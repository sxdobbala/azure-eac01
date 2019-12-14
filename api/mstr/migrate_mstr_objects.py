"""
This script will migrate MSTR objects to the local iserver. The script assumes that the release components are already copied to the EC2 instance using the S3 copy lambda. The folder path in EC2 instance till "mstr" folder will be passed as an input to the script. Ex: /opt/mstr/MicroStrategy/Migration/8.0/mstr

Sample S3 bucket - https://760182235631-opa-artifacts-opa.s3.amazonaws.com/opa-releases/8.0/mstr/

Requirements - 
- The package names should follow the naming convention - '<timestamp as per Washington D.C.>_D02(server_in_which_package_created)_<ticket no. and desc.>'.
- Folder structure expected for a release - 
    Under the directory "<release name>/mstr/", there should be 3 folders - "undo"(created if not exists), "components" and "procedures"
- There will be only one "migration_file" for all the releases. It'll list all the packages migrated for each release.
- The header name used in the migration_file for each release is same as the value passed for the argument "release_name" when running the script.
- The "migration_file" being passed is not supposed to be updated/modified manually anytime.

Script Logic - 
Step 1- The script compares the packages in the "components" folder and the package names in the "migration_file" (contains list of packages that were run on MSTR QA) to figure out the new packages that need to be migrated.
Step 2- The script gets the list of packages from "migration file" with timestamps greater than the "new package"(that need to be migrated to QA) or greater than the min. timestamp of multiple new packages.
Step 3- Sort the new list of packages which includes package list generated from the above step(step-2) and the new package(s) (from step-1) in ascending order.
Step 4- Run the the packages mentioned in the list generated from previous step(step-3), i.e. new packages + (already existing)packages with timestamp greater than the new package(s), as per the sorted order.
"""
#!/usr/bin/env python3
import os
import pwd
import grp
import stat
import sys
import argparse
import datetime
from string import Template
import json
import socket
import mstr_utility
import yaml

IMPORT_PACKAGE_TEMPLATE = Template('IMPORT PACKAGE "$package_name" $project_tag;\n')
UNDO_PACKAGE_TEMPLATE = Template(
    'CREATE UNDOPACKAGE "$undo_package_name" $project_tag FROM PACKAGE "$package_name";\n'
)
UPDATE_PROJ_DESC_TEMPLATE = Template(
    'ALTER PROJECT CONFIGURATION DESCRIPTION "$release_name" IN PROJECT "$project_name";\n'
)
RELEASE_DEFINITION_FILE = "/opt/opa/local/current_release/releaseDefinition.yml"


def execute_cmd_manager_script_at_location(script_path, mstr_info):
    mstr_utility.execute_command(
        mstr_info["default_projectsource"],
        mstr_info["mstr_username"],
        mstr_info["mstr_password"],
        script_path,
    )


def execute_cmd_manager_script(script, mstr_info):
    mstr_utility.execute_cmd_mngr_script(
        mstr_info["default_projectsource"],
        mstr_info["mstr_username"],
        mstr_info["mstr_password"],
        script,
    )


def create_undo_package(package_path, project_tag, mstr_info):
    """ It creates an undo package with the name "<timestamp_undo_<package_name>" at location "/<release>/mstr/undo" for the package passed """
    undo_directory_path = os.path.join(mstr_info["folder_name"], "undo")
    os.makedirs(undo_directory_path, exist_ok=True)
    set_path_ownership(undo_directory_path, "mstr")
    set_read_write_exec_modes(undo_directory_path)

    package_name = os.path.basename(package_path)

    undo_package_name = (
        undo_directory_path
        + "/"
        + "{:%Y%m%d%H%M%S}".format(datetime.datetime.now())
        + "_undo_"
        + package_name
    )

    undo_script = UNDO_PACKAGE_TEMPLATE.substitute(
        undo_package_name=undo_package_name,
        package_name=package_path,
        project_tag=project_tag,
    )
    execute_cmd_manager_script(undo_script, mstr_info)


def import_package(package_path, project_tag, mstr_info):
    import_script = IMPORT_PACKAGE_TEMPLATE.substitute(
        package_name=package_path, project_tag=project_tag
    )
    execute_cmd_manager_script(import_script, mstr_info)


def execute_mstr_package(package_path, mstr_info):
    package = os.path.basename(package_path)

    if "configuration" in package.lower():
        project_tag = ""
    else:
        project_tag = 'FOR PROJECT "' + mstr_info["mstr_project_name"] + '"'

    create_undo_package(package_path, project_tag, mstr_info)
    import_package(package_path, project_tag, mstr_info)


def set_path_ownership(path, owner):
    uid = pwd.getpwnam(owner).pw_uid
    gid = grp.getgrnam(owner).gr_gid
    os.chown(path, uid, gid)


def set_read_write_exec_modes(file):
    """Set the file modes to read and write by owner, group and others, and to execute by owner and group only."""
    os.chmod(file, 0o776)  # -rwx-rwx-rw-


def refresh_schema_in_all_servers(mstr_info, general_config):
    """ After importing packages in MSTR, it refreshes the MSTR schema to reflect all the object changes in MSTR """
    projectsource_template_ini = general_config["projectsource_template_ini"]

    servers = mstr_utility.list_all_servers_in_cluster(
        mstr_info["default_projectsource"],
        mstr_info["mstr_username"],
        mstr_info["mstr_password"],
    )

    print("Refreshing schema...")
    for server in servers:
        mstr_utility.add_projectsource(projectsource_template_ini, server)
        mstr_utility.refresh_schema(
            server,
            mstr_info["mstr_username"],
            mstr_info["mstr_password"],
            mstr_info["mstr_project_name"],
        )
    print("Completed schema refresh")


def get_package_list_from_migration_file(release_identifier, migration_file):
    """ 
    It returns the already migrated packages list from the migration file for the release for which script is being run.
    The 'migration_file' should not be updated manually.
    """
    release_data = {}

    if not os.path.isfile(migration_file):
        open(migration_file, "w").close()
        print(f"Migration file created: {migration_file}")
        return []

    with open(migration_file, "r") as mig_file:
        release_data = yaml.safe_load(mig_file)

    migrated_packages = []

    if release_data and release_identifier in release_data:
        migrated_packages = release_data[release_identifier]

    return migrated_packages


def get_threshold_package(release_packages, migrated_packages):
    """ 
    Returns the threshold package which is the min. of the list of (new packages + (already existing)packages with timestamp greater than the new package(s) in ascending sorted order). 
    The package names should follow the naming convention - '<timestamp>_D02(server_in_which_package_created)_<ticket no. and desc.>'.
    """
    diff_packages = list(set(release_packages).difference(migrated_packages))
    if diff_packages:
        threshold_package = release_packages.index(min(diff_packages))
    else:
        threshold_package = None

    if migrated_packages:
        print(
            f"Last package migrated to {args.mstr_project_name}: {migrated_packages[-1]}"
        )
    return threshold_package


def copy_mstr_procedures(mstr_procedures_src, mstr_procedures_dest):
    set_read_write_exec_modes(mstr_procedures_dest)

    if os.path.exists(mstr_procedures_src):
        print("Syncing MSTR procedures")
        mstr_utility.sync_user_folders(mstr_procedures_src, mstr_procedures_dest)
        print("Syncing MSTR procedures completed")
    else:
        print("No procedures to copy.")


def migrate_mstr_packages(
    release_packages, threshold_package, release_identifier, mstr_info
):
    """Migrates all the packages depending on whether it's a migration package(mmp) or a command manager script(scp) """
    if threshold_package is None:
        print("No delta packages found. All changes are already migrated.")
        return

    # packages_to_migrate is the delta of packages list and thus, it holds the new packages to be run + the packages that need to be redone
    packages_to_migrate = release_packages[threshold_package:]

    components_path = os.path.join(mstr_info["folder_name"], "components")

    packages_migrated = []
    print("Starting importing all MSTR packages and scripts")
    try:
        for package in packages_to_migrate:
            package_path = os.path.join(components_path, package)

            if package.endswith(".mmp"):
                execute_mstr_package(package_path, mstr_info)
            elif package.endswith(".scp"):
                execute_cmd_manager_script_at_location(package_path, mstr_info)
            else:
                print("File migration skipped for: " + package)
                continue

            packages_migrated.append(package)
    finally:
        with open(mstr_info["migration_file"]) as mig_file:
            release_data = yaml.safe_load(mig_file)

        # Required for the first run when the migration file will be empty
        if not release_data:
            release_data = {}

        if release_identifier in release_data:
            release_data[release_identifier].extend(packages_migrated)
        else:
            release_data[release_identifier] = packages_migrated

        with open(mstr_info["migration_file"], "w") as mig_file:
            yaml.dump(release_data, mig_file)

    print("Completed importing MSTR objects")


def update_project_desc_with_release_name(release_identifier, mstr_info):
    update_proj_desc_script = UPDATE_PROJ_DESC_TEMPLATE.substitute(
        project_name=mstr_info["mstr_project_name"], release_name=release_identifier
    )
    execute_cmd_manager_script(update_proj_desc_script, mstr_info)


def get_release_name():
    with open(RELEASE_DEFINITION_FILE, "r") as release_def_file:
        release_info = yaml.safe_load(release_def_file)
        release_name = release_info["mstrContent"][0]
        return release_name


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Provide MSTR environment details and project configurations"
    )
    parser.add_argument(
        "--mstr_project_name",
        type=str,
        help="MicroStrategy project name",
        required=True,
    )
    parser.add_argument(
        "--mstr_username", type=str, help="Microstrategy Username", required=True
    )
    parser.add_argument(
        "--mstr_password_key", type=str, help="Microstrategy Password", required=True
    )
    parser.add_argument(
        "--migration_base_folder",
        type=str,
        help="Parent folder containing the release folders",
        required=True,
    )
    parser.add_argument(
        "--migration_file",
        type=str,
        help="File containing the list of objects migrated",
    )
    parser.add_argument(
        "--migration_strategy",
        type=str,
        choices=["full", "delta"],
        default="delta",
        help="Pass 'full' or 'delta' for the migration approach to follow",
        required=True,
    )
    args = parser.parse_args()

    mstr_password = mstr_utility.get_parameter(args.mstr_password_key)

    with open(os.path.join(sys.path[0], "general_config.json"), "r") as f:
        general_config = json.load(f)

    release_identifier = get_release_name()
    release_folder = f"{args.migration_base_folder}/{release_identifier}/mstr"
    if args.migration_file is None:
        migration_file = f"{args.migration_base_folder}/migration_file.yaml"
    else:
        migration_file = args.migration_file

    mstr_procedures_src = release_folder + "/procedures"
    mstr_procedures_dest = general_config["mstr_procedures_dest"]
    copy_mstr_procedures(mstr_procedures_src, mstr_procedures_dest)

    print(f"{args.migration_strategy.title()} migration initiated")

    components_path = release_folder + "/components"
    release_packages = sorted(os.listdir(components_path))

    migrated_packages = get_package_list_from_migration_file(
        release_identifier, migration_file
    )

    mstr_info = {}
    mstr_info["default_projectsource"] = general_config["default_projectsource"]
    mstr_info["mstr_project_name"] = args.mstr_project_name
    mstr_info["mstr_username"] = args.mstr_username
    mstr_info["mstr_password"] = mstr_password
    mstr_info["migration_file"] = migration_file
    mstr_info["folder_name"] = release_folder

    if args.migration_strategy == "delta":
        # threshold_package is the package from which onwards all the packages(incl. the threshold package) needs to be run
        threshold_package = get_threshold_package(release_packages, migrated_packages)
    else:
        # For "full" migration, the threshold package should be the first one since all packages need to be migrated
        threshold_package = 0

    migrate_mstr_packages(
        release_packages, threshold_package, release_identifier, mstr_info
    )

    update_project_desc_with_release_name(release_identifier, mstr_info)
    print("Updated the MSTR project description with the current release name")

    refresh_schema_in_all_servers(mstr_info, general_config)