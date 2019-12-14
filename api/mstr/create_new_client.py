# Requirements - Files - "clientFolderACEsTemplate.scp" and "EGRclientFolderACEsTemplate.scp" in "/tmp/" folder
import argparse
import logging
import socket
import sys
import datetime
import os
import json
import subprocess
import boto3
from string import Template
from shutil import copyfile
from configparser import SafeConfigParser
from mstrio import microstrategy
from os import path
import redshift_utility as redshift
import mstr_utility
import re
import csv

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def get_set_of_existing_objects(connection, object_type, object_list):
    """  Returns list of MSTR Objects if exist  """
    objects = mstr_utility.execute_get_api(connection, "/" + object_type)
    return set(object_list).intersection(set([obj["name"] for obj in objects]))


def objects_exist(connection, object_type, object_name):
    objects = mstr_utility.execute_get_api(connection, "/" + object_type)
    return any(obj["name"] == object_name for obj in objects)


def get_object_id(connection, object_type, object_name):
    """ Returns MSTR Object ID """
    objects = mstr_utility.execute_get_api(connection, "/" + object_type)
    for obj in objects:
        if obj["name"] == object_name:
            return obj["id"]
    return None


def create_user_group(connection, group_name, parent_group_id):
    """ Creates MSTR User Group """
    group = {
        "name": group_name,
        "description": group_name,
        "memberships": [parent_group_id],
    }
    mstr_utility.execute_post_api(connection, "/usergroups", group)


def create_client_folder(connection, folder_name, parentFolderID, hiddenStatus):
    """ Creates MSTR folder using API """
    folder = {"name": folder_name,
              "description": folder_name, "parent": parentFolderID}
    if hiddenStatus is True:
        # doesn't work through MSTR API yet, handled via command manager
        folder["hidden"] = True

    mstr_utility.execute_post_api(connection, "/folders", folder)


def generate_client_ace_file(template_file, client_ace_file, arguments):
    """ Generates MSTR Command Manager script file for modifying ACE of newly created folders  """
    if not path.exists(template_file):
        print("Failed. Template file not found - " + template_file)
        return None

    with open(template_file) as f:
        substituted_file = f.read()
        for term in arguments:
            substituted_file = substituted_file.replace(term, arguments[term])

    with open(client_ace_file, "w") as f:
        f.write(substituted_file)


def create_new_mstr_db_login(mstr_login_name, group_name, client_username):
    """ Creates a new MSTR Database Login for client """
    cmd_mgr_template = Template(
        'CREATE DBLOGIN "$mstr_login_name" LOGIN "$client_username" PASSWORD "";\n'
    )
    cmd_mgr_script = cmd_mgr_template.substitute(
        client_username=client_username.lower(),
        mstr_login_name=mstr_login_name,
    )
    cmd_mgr_file = "/tmp/provision-client-" + group_name + "_new_db_login.scp"
    with open(cmd_mgr_file, mode="wt") as f:
        f.write(cmd_mgr_script)
    return cmd_mgr_file


def alter_mstr_db_login(mstr_login_name, group_name, client_username):
    """ Alters existing MSTR DB Login """
    cmd_mgr_template = Template(
        'ALTER DBLOGIN "$mstr_login_name" LOGIN "$client_username" PASSWORD "";\n'
    )
    cmd_mgr_script = cmd_mgr_template.substitute(
        client_username=client_username.lower(),
        mstr_login_name=mstr_login_name,
    )
    cmd_mgr_file = "/tmp/provision-client-" + \
        group_name + "_alter_mstr_db_login.scp"
    with open(cmd_mgr_file, mode="wt") as f:
        f.write(cmd_mgr_script)
    return cmd_mgr_file


def create_new_mstr_db_conn(mstr_login_name, group_name, mstr_conn_name, odbc_entry):
    """ Creates a new MSTR DB Connection """
    cmd_mgr_template = Template(
        'CREATE DBCONNECTION "$mstr_conn_name" $odbc_entry DEFAULTLOGIN "$mstr_login_name";\n'
    )
    cmd_mgr_script = cmd_mgr_template.substitute(
        mstr_login_name=mstr_login_name,
        mstr_conn_name=mstr_conn_name,
        odbc_entry=odbc_entry,
    )
    cmd_mgr_file = "/tmp/provision-client-" + group_name + "_new_db_conn.scp"
    with open(cmd_mgr_file, mode="wt") as f:
        f.write(cmd_mgr_script)
    return cmd_mgr_file


def alter_mstr_db_conn(mstr_login_name, group_name, mstr_conn_name, odbc_entry):
    """ Alters existing MSTR DB Connection """
    cmd_mgr_template = Template(
        'ALTER DBCONNECTION "$mstr_conn_name" $odbc_entry DEFAULTLOGIN "$mstr_login_name";\n'
    )
    cmd_mgr_script = cmd_mgr_template.substitute(
        mstr_login_name=mstr_login_name,
        mstr_conn_name=mstr_conn_name,
        odbc_entry=odbc_entry,
    )
    cmd_mgr_file = "/tmp/provision-client-" + \
        group_name + "_alter_mstr_db_conn.scp"
    with open(cmd_mgr_file, mode="wt") as f:
        f.write(cmd_mgr_script)
    return cmd_mgr_file


def del_mstr_conn_mapping(
    group_name, mstr_server_name, mstr_username, mstr_db_instance, mstr_password, project
):
    """ Delete MSTR Connection Mapping """
    cmd_mgr_template = Template(
        'DELETE CONNECTION MAP FOR GROUP "$group_name" DBINSTANCE "$mstr_db_instance" FOR PROJECT "$project";\n'
    )
    cmd_mgr_script = cmd_mgr_template.substitute(
        group_name=group_name, mstr_db_instance=mstr_db_instance, project=project)
    mstr_utility.execute_cmd_mngr_script(
        mstr_server_name,
        mstr_username,
        mstr_password,
        cmd_mgr_script,
    )
    print(
        f"Connection mapping for user group {group_name} and db instance {mstr_db_instance} deleted successfully")


def del_if_conn_mapp_exists(
    group_name, mstr_server_name, mstr_username, mstr_db_instance, mstr_password, project
):
    """ Check if connection mapping already exists for the user group and db instance"""
    conn_map_param = [group_name, mstr_db_instance]
    cmd_mgr_template = Template(
        'LIST ALL CONNECTION MAP FOR PROJECT "$project";\n'
    )
    cmd_mgr_script = cmd_mgr_template.substitute(project=project)
    results_csv = mstr_utility.get_cmd_mngr_script_result_csv(
        mstr_server_name,
        mstr_username,
        mstr_password,
        cmd_mgr_script,
    )
    with open(results_csv) as csvfile:
        users_csv_obj = csv.reader(csvfile)
        conn_map_list = list(filter(None, users_csv_obj))

    for row in conn_map_list:
        # Retain group name and database instance
        [row.pop(index) for index in range(-4, 1)]
        if row == conn_map_param:
            del_mstr_conn_mapping(
                group_name, mstr_server_name, mstr_username, mstr_db_instance, mstr_password, project
            )


def create_mstr_conn_mapping(
    group_name, mstr_server_name, mstr_username, mstr_db_instance, mstr_conn_name, mstr_login_name, mstr_password, project

):
    """ Creates MSTR Connection Mapping for client user group """

    del_if_conn_mapp_exists(group_name, mstr_server_name, mstr_username, mstr_db_instance, mstr_password, project
                            )
    cmd_mgr_template = Template(
        'CREATE CONNECTION MAP FOR USER GROUP "$group" DBINSTANCE "$mstr_db_instance" DBCONNECTION "$mstr_conn_name" DBLOGIN "$mstr_login_name" FOR PROJECT "$project";\n'
    )
    cmd_mgr_script = cmd_mgr_template.substitute(
        group=group_name,
        mstr_login_name=mstr_login_name,
        mstr_conn_name=mstr_conn_name,
        mstr_db_instance=mstr_db_instance,
        project=project,
    )
    cmd_mgr_file = f"/tmp/provision-client-{group_name}_{mstr_db_instance.replace(' ', '')}_create_conn_map.scp"
    with open(cmd_mgr_file, mode="wt") as f:
        f.write(cmd_mgr_script)
    return cmd_mgr_file


def get_backup_filename(src):
    """ Backup and Return filename """
    dst = src + "_bak_" + "{:%Y%m%d%H%M%S}".format(datetime.datetime.now())
    copyfile(src, dst)
    return dst


def add_odbc_entry(
    odbc_file,
    client_odbc_entry,
    odbc_desc,
    template_file,
    redshift_client_database,
    redshift_host,
    redshift_client_username,
):
    """  Adds ODBC entry to odbc ini file"""
    get_backup_filename(odbc_file)
    if client_odbc_entry not in open(odbc_file).read():
        parser = SafeConfigParser(strict=False)
        parser.optionxform = str
        parser.read(odbc_file)
        parser.set("ODBC Data Sources", client_odbc_entry, odbc_desc)
        with open(odbc_file, "w") as configfile:
            parser.write(configfile, space_around_delimiters=False)

        sed_params = f'cat {template_file} | sed -e "s,client_odbc_entry,{client_odbc_entry}," -e "s,redshift_client_database,{redshift_client_database},"  -e "s,redshift_host,{redshift_host},"  -e "s,redshift_client_username,{redshift_client_username}," >> {odbc_file}'
        sed_output = subprocess.check_output(
            sed_params, shell=True).decode("utf-8")
        print("Configured client odbc entry: " + sed_output)

    else:
        parser = SafeConfigParser(strict=False)
        parser.optionxform = str
        parser.read(odbc_file)
        parser.set("ODBC Data Sources", client_odbc_entry, odbc_desc)
        parser.set(client_odbc_entry, "Database", redshift_client_database)
        parser.set(client_odbc_entry, "Server", redshift_host)
        parser.set(client_odbc_entry, "DbUser", redshift_client_username)
        with open(odbc_file, "w") as configfile:
            parser.write(configfile, space_around_delimiters=False)


def setup_new_db_conn(
    conn,
    group_name,
    mstr_login_name,
    mstr_conn_name,
    mstr_db_instance,
    odbc_entry,
    project,
    client_username,
    mstr_server_name,
    mstr_username,
    mstr_password,
):
    """Removes existing db connection, db login, connection mapping"""
    if objects_exist(conn, "dbLogins", mstr_login_name):
        print("MSTR DB login already exists. Hence it will be updated")
        cmd_mgr_file = alter_mstr_db_login(
            mstr_login_name, group_name, client_username
        )
    else:
        print("MSTR DB login does not exist. Hence it will be created")
        cmd_mgr_file = create_new_mstr_db_login(
            mstr_login_name, group_name, client_username
        )

    mstr_utility.execute_command(
        mstr_server_name, mstr_username, mstr_password, cmd_mgr_file
    )
    print("Completed updating MSTR DB login with name " + mstr_login_name)

    if objects_exist(conn, "folders/preDefined/81", mstr_conn_name):
        print("MSTR conn name already exists. Hence it will be updated")
        cmd_mgr_file = alter_mstr_db_conn(
            mstr_login_name,
            group_name,
            mstr_conn_name,
            odbc_entry if odbc_entry != "XQUERY" else "",
        )
    else:
        print("MSTR conn name does not exist. Hence it will be created")
        cmd_mgr_file = create_new_mstr_db_conn(
            mstr_login_name, group_name, mstr_conn_name, odbc_entry
        )

    mstr_utility.execute_command(
        mstr_server_name, mstr_username, mstr_password, cmd_mgr_file
    )
    print("Completed updating MSTR Connection with name " + mstr_conn_name)

    # Add new connection mapping for new client
    cmd_mgr_file = create_mstr_conn_mapping(
        group_name, mstr_server_name, mstr_username, mstr_db_instance, mstr_conn_name, mstr_login_name, mstr_password, project

    )
    mstr_utility.execute_command(
        mstr_server_name, mstr_username, mstr_password, cmd_mgr_file
    )


def check_and_return_password(password_key):
    """ Returns password from ssm store if exist; else generates password and adds it to ssm store"""
    ssm = boto3.client("ssm")  # For catching ParamNotFound exception
    try:
        password = mstr_utility.get_parameter(password_key)

    except ssm.exceptions.ParameterNotFound:
        password = mstr_utility.generate_password(12)
        mstr_utility.put_parameter(
            password_key, password, f"This is the password value for {password_key}"
        )
    return password


def insert_into_opa_master(client_id, lambda_params, opa_master_lambda):
    """ Inserts values into OPA_Master table """
    with open(
        os.path.join(sys.path[0], "opa-master-payload-template.json"), "r"
    ) as jsonfile:
        lambda_payload = json.load(jsonfile)

    lambda_payload["body"]["clientId"] = client_id
    lambda_payload["body"]["data"] = lambda_params

    mstr_utility.invoke_lambda(opa_master_lambda, json.dumps(lambda_payload))


def load_mstr_procedures(mstr_procedures_dest):
    """ Loads MSTR command manager user procedures """
    mstr_procedures_src = os.path.join(sys.path[0], "procedures")
    if not mstr_utility.sync_user_folders(mstr_procedures_src, mstr_procedures_dest):
        print("Unable to copy required procedures. Exiting the program.")
        sys.exit(1)
    print("Command Manager Procedures Loaded Sucessfully")


def return_client_user_group_id(conn, client_id):
    """  Check and Return MSTR Client user group ID """
    # Verify client group is present in MSTR
    if objects_exist(conn, "usergroups", client_id):
        print("Client group already exists")
    else:
        parent_group_id = get_object_id(conn, "usergroups", "Clients")
        if parent_group_id is not None:
            create_user_group(conn, client_id, parent_group_id)
            print("Client user Group created.")
        else:
            print("Parent group 'Clients' does not exist. Client group creation failed!")
            sys.exit(1)
    client_group_guid = get_object_id(conn, "usergroups", args.client_id)
    print("client_group_guid - " + client_group_guid)
    return client_group_guid


def create_cube_builder_user(conn, client_group_guid, cubebuilder_user, cubebuilder_password):
    """ Creates cube builder user if not exists """
    admin_group_guid = get_object_id(
        conn, "usergroups", "26_MicroStrategy Connection Mapping Admins"
    )
    group_list = []
    group_list.append(client_group_guid)
    group_list.append(admin_group_guid)
    if mstr_utility.user_exists(conn, cubebuilder_user):
        print("Cube builder user already exists")
    else:
        mstr_utility.create_user(
            conn, cubebuilder_user, cubebuilder_password, group_list
        )
        print("Cube builder user created")


def create_client_specific_folders(
    project_conn,
    folders_required,
    hidden_folders,
    reports_path,
    mstr_project_name,
    mstr_server_name,
    mstr_username,
    mstr_password,
    parent_folder,
):
    """ Creates Client Specific Folders """
    folders_present = get_set_of_existing_objects(
        project_conn, "folders/preDefined/7?limit=-1", folders_required
    )

    # Ref https://lw.microstrategy.com/msdz/MSDL/GARelease_Current/docs/ReferenceFiles/reference/com/microstrategy/webapi/EnumDSSXMLFolderNames.html to know about constant preDefined/7
    folders_absent = set(folders_required) - set(folders_present)
    if not folders_absent:
        print("Client folder already exists! Client specific folders creation skipped.")
    else:
        parent_folder_id = get_object_id(
            project_conn, "folders/preDefined/1?limit=-1", parent_folder
        )
        if parent_folder_id is not None:
            for folder in folders_absent:
                if folder in hidden_folders:
                    create_client_folder(
                        project_conn, folder, parent_folder_id, True)
                    mstr_utility.hide_folder(
                        folder,
                        reports_path,
                        mstr_project_name,
                        mstr_server_name,
                        mstr_username,
                        mstr_password,
                    )
                else:
                    create_client_folder(
                        project_conn, folder, parent_folder_id, False)
            print("Client folders created - " + ", ".join(folders_absent))
        else:
            print(
                "Parent group '"
                + parent_folder
                + "' does not exist. Client folder creation failed!"
            )
            sys.exit(1)


def add_ace_for_folders(client_id, ace_template_file, ace_cmd_mgr_file, arguments, mstr_server_name, mstr_username, mstr_password):
    """ Adds MSTR Access Control List for Client Folders  """
    client_folder_ace_file_template = os.path.join(
        sys.path[0], ace_template_file
    )
    client_ace_file = (
        "/tmp/"
        + "{:%Y%m%d%H%M%S}".format(datetime.datetime.now())
        + "_"
        + client_id
        + ace_cmd_mgr_file
    )

    generate_client_ace_file(
        client_folder_ace_file_template, client_ace_file, arguments
    )

    if path.exists(client_ace_file):
        mstr_utility.execute_command(
            mstr_server_name, args.mstr_username, mstr_password, client_ace_file
        )
        print("ACE for client folders updated.")
    else:
        print(
            "Failure: Error generating client specific ACE file. ACEs not updated for client folders"
        )
        sys.exit(1)


def create_client_redshift_artifacts(args):

    logger.info("Establishing Redshift connection")
    host = args.redshift_host
    port = args.redshift_port
    database = args.client_reporting_db
    creds = redshift.get_cluster_credentials(
        args.redshift_username, args.redshift_id)

    with redshift.get_connection(
        host, port, database, creds["DbUser"], creds["DbPassword"]
    ) as conn:
        logger.info("Creating client Redshift user")
        client_username = args.redshift_client_username
        redshift.create_user(conn, client_username)
        redshift.alter_user_search_path(
            conn, client_username, "public, rep, daily_rep, rw")
        redshift.create_db_user_group(
            conn, f"{args.client_id.lower()}_opa_developers")

        logger.info("Creating client Redshift database")
        client_database = args.redshift_client_database
        redshift.create_database(conn, client_database, client_username)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Create a new client user group and folders")
    parser.add_argument("--client_id",
                        help="Client identifier e.g. H123456", required="true")
    parser.add_argument("--client_name", required="true",
                        help="Client name which will be used to create report folders")
    parser.add_argument("--client_has_egr", choices=["Y", "N"], required="true",
                        help="Pass 'Y' if the client has Employer Group reports(EGR) support")
    parser.add_argument("--client_reporting_db",
                        help="Client Reporting Database", required="true")
    parser.add_argument("--mstr_project_name", type=str,
                        help="MicroStrategy project name")
    parser.add_argument("--mstr_username",
                        help="MicroStrategy UserName", required="true")
    parser.add_argument("--mstr_password_key",
                        help="MicroStrategy Password", required="true")
    parser.add_argument("--redshift_host",
                        help="Redshift Hostname", required="true")
    parser.add_argument("--redshift_port",
                        help="Redshift Port", required="true")
    parser.add_argument("--redshift_id",
                        help="Redshift ID", required="true")
    parser.add_argument("--redshift_username",
                        help="Redshift Username", required="true")
    parser.add_argument("--redshift_client_database",
                        help="Client Database", required="true")
    parser.add_argument("--redshift_client_username",
                        help="Client Database User", required="true")
    parser.add_argument("--opa_master_lambda",
                        help="Specify the opa master lambda function name", required="true")
    args = parser.parse_args()

    # Getting configs
    with open(os.path.join(sys.path[0], "general_config.json"), "r") as f:
        general_config = json.load(f)

    with open(os.path.join(sys.path[0], "project_config.json"), "r") as f:
        project_config = json.load(f)

    logger.info("Creating client Redshift artifacts")
    create_client_redshift_artifacts(args)

    # Load required procedure to user procedures folder
    load_mstr_procedures(general_config["mstr_procedures_dest"])

    odbc_file = general_config["odbc_file"]
    redshift_odbc_template_file = os.path.join(
        sys.path[0], project_config["template_file"]
    )
    client_odbc_entry = project_config["client_odbc_entry"] + args.client_id
    mstr_oadw_database_instance = project_config["mstr_oadw_database_instance"]
    mstr_oadw_conn_name = args.client_id + \
        project_config["mstr_oadw_connection_name"]
    mstr_rw_database_instance = project_config["mstr_rw_database_instance"]
    mstr_login_name = args.client_id + project_config["mstr_login_name"]
    projectsource_template_ini = general_config["projectsource_template_ini"]
    redshift_odbc_desc = general_config["redshift_odbc_desc"]

    # Folder names that'll be created for the client
    reports_path = "Public Objects\\Reports"
    parent_folder = "Reports"
    client_users = args.client_name + " Users"
    client_shared_reports = args.client_name + " Shared Reports"
    client_custom_reports = args.client_name + " Custom Reports"
    client_shared_registries = args.client_name + " Shared Registries"
    cubebuilder_user = args.client_id + "_Cube Builder"

    mstr_server_name = socket.gethostname()
    mstr_utility.add_projectsource(
        projectsource_template_ini, mstr_server_name)
    print("Project Source configuration done successfully.")

    # Creating the client specific password keys
    # Assuming hostname is of form env-[0-9].xxxxx
    environment_prefix = re.search(r"env-(\d+)", mstr_server_name)[0]
    cube_builder_password_key = (
        f"{environment_prefix}.{args.client_id}.cube-builder-password"
    )

    mstr_password = mstr_utility.get_parameter(args.mstr_password_key)

    # Generate client specific passwords if not already exists
    cubebuilder_password = check_and_return_password(cube_builder_password_key)
    redshift_client_password = ""

    # Add ODBC entry for new client database
    add_odbc_entry(
        odbc_file,
        client_odbc_entry,
        redshift_odbc_desc,
        redshift_odbc_template_file,
        args.redshift_client_database.lower(),
        args.redshift_host,
        args.redshift_client_username.lower(),
    )
    print("Updated ODBC file with the client odbc entry")

    conn = mstr_utility.get_mstr_connection(args.mstr_username, mstr_password)
    conn.connect()
    client_group_guid = return_client_user_group_id(conn, args.client_id)
    create_cube_builder_user(conn, client_group_guid,
                             cubebuilder_user, cubebuilder_password)

    odbc_entry = f'ODBCDSN "{client_odbc_entry}"'

    setup_new_db_conn(
        conn,
        args.client_id,
        mstr_login_name,
        mstr_oadw_conn_name,
        mstr_oadw_database_instance,
        odbc_entry,
        args.mstr_project_name,
        args.redshift_client_username,
        mstr_server_name,
        args.mstr_username,
        mstr_password,
    )

    setup_new_db_conn(
        conn,
        args.client_id,
        mstr_login_name,
        mstr_oadw_conn_name,
        mstr_rw_database_instance,
        odbc_entry,
        args.mstr_project_name,
        args.redshift_client_username,
        mstr_server_name,
        args.mstr_username,
        mstr_password,
    )
    print(
        "DB connection setup completed (Created new DB login, DB connection, connection map for client user group and altered db instance)."
    )

    conn.close()

    project_conn = mstr_utility.get_mstr_project_connection(
        args.mstr_username, mstr_password, args.mstr_project_name
    )
    project_conn.connect()

    folders_required = [
        client_users,
        client_shared_reports,
        client_custom_reports,
        client_shared_registries,
    ]
    hidden_folders = [client_shared_registries]
    create_client_specific_folders(project_conn,
                                   folders_required,
                                   hidden_folders,
                                   reports_path,
                                   args.mstr_project_name,
                                   mstr_server_name,
                                   args.mstr_username,
                                   mstr_password,
                                   parent_folder)

    ace_template_file = "client_folder_aces_template.scp"
    ace_cmd_mgr_file = "client_folder_aces.scp"
    arg_terms = [
        "<client_users>",
        "<client_shared_reports>",
        "<client_custom_reports>",
        "<client_shared_registries>",
        "<client_id>",
        "<path>",
        "<mstr_project_name>",
    ]
    arg_values = [
        client_users,
        client_shared_reports,
        client_custom_reports,
        client_shared_registries,
        args.client_id,
        reports_path,
        args.mstr_project_name,
    ]
    ace_arguments = dict(zip(arg_terms, arg_values))
    add_ace_for_folders(args.client_id, ace_template_file, ace_cmd_mgr_file,
                        ace_arguments, mstr_server_name, args.mstr_username, mstr_password)

    client_shared_registries_guid = get_object_id(
        project_conn, "folders/preDefined/7?limit=-1", client_shared_registries
    )
    print(f"client_shared_registries GUID{client_shared_registries_guid}")

    if "Y" in args.client_has_egr:

        client_employer_groups_reports = args.client_name + " Employer Group Reports"
        create_client_specific_folders(project_conn,
                                       [client_employer_groups_reports],
                                       hidden_folders,
                                       reports_path,
                                       args.mstr_project_name,
                                       mstr_server_name,
                                       args.mstr_username,
                                       mstr_password,
                                       parent_folder)

        egr_client_folder_ace_file_template = "egr_client_folder_aces_template.scp"
        egr_ace_cmd_mgr_file = "egr_client_folder_aces.scp"

        arg_terms = [
            "<client_employer_groups_reports>",
            "<client_id>",
            "<path>",
            "<mstr_project_name>",
        ]
        arg_values = [
            client_employer_groups_reports,
            args.client_id,
            reports_path,
            args.mstr_project_name,
        ]
        ace_arguments = dict(zip(arg_terms, arg_values))

        add_ace_for_folders(args.client_id, egr_client_folder_ace_file_template,
                            egr_ace_cmd_mgr_file, ace_arguments, mstr_server_name, args.mstr_username, mstr_password)

    else:
        print("Not an EGR client. Hence EGR folder is not created"
              )

    project_conn.close()

    # Update params
    lambda_param = {}
    lambda_param["mstr/guid_client_group"] = client_group_guid
    lambda_param["mstr/guid_registry_folder"] = client_shared_registries_guid
    lambda_param["cube_builder/password_key"] = cube_builder_password_key

    # Update keys into OPA Master
    insert_into_opa_master(args.client_id, lambda_param,
                           args.opa_master_lambda)

    # Restart iServer
    mstr_utility.restart_all_iservers(
        mstr_server_name, args.mstr_username, mstr_password
    )
    print("Restarted all the iServers.")
