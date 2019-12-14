"""
Purpose - This script will clean an MSTR project by deleting all unnecesary client folders, users, user groups, connection maps, DB connections, DB logins, ODBC file sections, user profiles, subscriptions and schedules as per requirement to use the project for backup.

Script Logic/flow - 
1. The script supports multiple clients being passed in client params for the script.
2. Delete all subscriptions if "delete_subscriptions" flag is set or when no "exclude_client_ids"/"exclude_client_names" are passed else do nothing.
3. Delete all schedules except the ones owned by "Administrator" if "delete_schedules" flag is set or when no "exclude_client_ids"/"exclude_client_names" are passed else do nothing.
4. If no "exclude_client_ids" and "exclude_client_names" are passed when running the script, it deletes users from "everyone" user group except the users under "System Administrators".
    1. If no "exclude_client_ids" and "exclude_client_names" - Deletes all users except "System Administrators".
    2. If "exclude_client_ids" are passed - Delete all users except the users in the "client group"(for the client IDs passed) and "System Administrators" 
5. Deletes connection map for the user groups being deleted for clients other than the ones passed to "exclude_client_ids" argument.
6. Delete DBConnections for clients other than the ones passed to "exclude_client_ids" argument.
7. Delete DBLogins for clients other than the ones passed to "exclude_client_ids" argument.
8. Delete sections from ODBC file which belong to clients other than the ones passed to "exclude_client_ids" argument.
9. Set 'H_Default_XX Database Connection' and 'H_Default_XX_Login' as default db connection and db login for following instance:
- OPA OADW Database Instance
- OPA RW Database Instance
- OPA XQ Database Instance
10. Delete user profiles for which users no more exist.
11. Delete client folders for clients other than the ones passed to "exclude_client_ids" argument by getting client names from (<client> shared registries and other similar folders created during client on-boarding) folders. Delete these folders for other clients- 
    1. <Client_Name> Users
    2. <Client_Name> Shared Reports
    3. <Client_Name> Custom Reports
    4. <Client_Name> Shared Registries
    5. <Client_Name> Employer Group Reports (For EGR Clients)
Note - 
- Deletion for a folder(client report folder, user profile folder), DBConnection and DBLogin is skipped if it has any dependent objects.
- To delete "subscriptions" or "schedules" for specific clients, "delete_subscriptions" or "delete_schedules" flags should NOT be set, they need to be manually deleted as we cannot identify what schedules and subscriptions belong to each client(for now).
"""
#!/usr/bin/env python3
import os
import sys
import json
import argparse
from string import Template
import mstr_utility
import re
import csv
from collections import defaultdict
import ast
from configparser import SafeConfigParser

DELETE_ALL_SUBSCRIPTIONS_TEMPLATE = Template(
    'DELETE ALL SUBSCRIPTIONS FROM PROJECT "$project_name";\n'
)
LIST_ALL_SCHEDULES_SCRIPT = "LIST ALL SCHEDULES;\n"
LIST_SCHEDULE_PROPERTIES_TEMPLATE = Template(
    'LIST PROPERTIES FOR SCHEDULE "$schedule_name";\n'
)
DELETE_SCHEDULE_TEMPLATE = Template('DELETE SCHEDULE "$schedule_name";\n')
LIST_ALL_DB_CONNECTIONS_SCRIPT = "LIST ALL DBCONNECTIONS;\n"
LIST_DB_CONNECTION_PROPERTIES_TEMPLATE = Template(
    'LIST ALL PROPERTIES FOR DBCONNECTION "$dbconnection_name";\n'
)
ALTER_DEFAULT_DB_LOGIN_FOR_DB_CONN_TEMPLATE = Template(
    'ALTER DBCONNECTION "$dbconnection_name" DEFAULTLOGIN "$dblogin_name";\n'
)
ALTER_DB_CONN_FOR_DB_INSTANCE_TEMPLATE = Template(
    'ALTER DBINSTANCE "$dbinstance_name" DBCONNECTION "$dbconnection_name";\n'
)

DB_CONNECTIONS_EXCLUDED_FROM_DELETION = ["STATISTICS", "Default"]
DB_LOGINS_EXCLUDED_FROM_DELETION = ["STATISTICS", "Default"]

# API object type ID ref. - https://lw.microstrategy.com/msdz/msdl/GARelease_Current/docs/ReferenceFiles/reference/com/microstrategy/webapi/EnumDSSXMLObjectTypes.html
MSTR_OBJECTTYPE_FOLDER = 8
MSTR_OBJECTTYPE_USER = 34
MSTR_OBJECTTYPE_USERGROUP = 34
MSTR_OBJECTTYPE_DBCONNECTION = 31
MSTR_OBJECTTYPE_DBLOGIN = 30
# API folder name ID ref. - https://lw.microstrategy.com/msdz/MSDL/GARelease_Current/docs/ReferenceFiles/reference/com/microstrategy/webapi/EnumDSSXMLFolderNames.html#DssXmlFolderNamePublicReports
MSTR_FOLDERNAME_PUBLICREPORTS = 7

ODBC_DATA_SOURCES_SECTION_IN_ODBCFILE = "ODBC Data Sources"


def get_list_of_objects(connection, object_type):
    """  Returns list of MSTR Object names of the type 'object_Type' passed to the function  """
    objects = mstr_utility.execute_get_api(connection, "/" + object_type)
    return objects


def get_object_id_if_exists(connection, object_type, object_name):
    """ Returns the object ID for the object passed to the function, if the object exists else it returns None"""
    objects = mstr_utility.execute_get_api(connection, "/" + object_type)
    for obj in objects:
        if obj["name"] == object_name:
            return obj["id"]
    return None


def get_clients_with_folders(report_folders, exclude_client_names):
    """ Returns other clients which have report folders specific to them in the project. It identifies <client name> based on the intitial report folders created for a client while client on-boarding. Eg - <Client_Name> Users, <Client_Name> Shared Reports, <Client_Name> Shared Registries and <Client_Name> Custom Reports """
    client_folders = defaultdict(int)
    for folder in report_folders:
        client_name_match_result = re.match(
            r"([A-Za-z0-9\s]+)\s(Users|Shared Reports|Shared Registries|Custom Reports)",
            folder,
        )
        if client_name_match_result:
            client_name = client_name_match_result.group(1)
            client_folders[client_name] += 1

    if exclude_client_names is None:
        exclude_client_names = []

    other_client_names = [
        client_key
        for (client_key, client_folder_count) in client_folders.items()
        if client_folder_count == 4 and client_key not in exclude_client_names
    ]
    return other_client_names


def delete_client_folders(project_conn, clients_to_be_deleted):
    """ Deletes folders like <Client_Name> Users, <Client_Name> Shared Reports, <Client_Name> Shared Registries, <Client_Name> Custom Reports and <Client_Name> Employer Group Reports (For EGR Clients) for other clients. It skips folders which have dependent objects on them in other folders. """
    client_folder_suffixes = [
        "Users",
        "Shared Reports",
        "Shared Registries",
        "Custom Reports",
        "Employer Group Reports",
    ]

    for client in clients_to_be_deleted:
        for folder_suffix in client_folder_suffixes:
            client_folder = client + " " + folder_suffix
            client_folder_id = get_object_id_if_exists(
                project_conn, "folders/preDefined/7?limit=-1", client_folder
            )
            if client_folder_id:
                delete_object(
                    project_conn,
                    client_folder_id,
                    f"Folder - {client_folder}",
                    MSTR_OBJECTTYPE_FOLDER,
                )


def get_member_details_under_group(proj_instance_conn, parent_user_group):
    """ Returns users/members which fall under the "parent_user_group" user group passed to the function """
    parent_group_id = get_object_id_if_exists(
        proj_instance_conn,
        f"usergroups?nameBegins={parent_user_group}&limit=-1",
        parent_user_group,
    )
    group_details = mstr_utility.execute_get_api(
        proj_instance_conn, f"/usergroups/{parent_group_id}"
    )
    group_members = group_details["members"]
    return group_members


def delete_user_profile_folders(project_conn, all_user_details):
    """ Deletes user profile folders under 'Profiles' folder for users which don't exist in the project source"""
    all_user_names = [user["name"] for user in all_user_details]

    user_profiles_folder_id = get_object_id_if_exists(
        project_conn, "folders", "Profiles"
    )
    user_profile_folders = get_list_of_objects(
        project_conn, f"folders/{user_profiles_folder_id}"
    )

    for user_profile_folder in user_profile_folders:
        # Matches characters enclosed within parantheses '()' as devloper login username. Eg. 'test user (test1)' => matches 'test1'
        user_name_match_result = re.match(
            r"(.+)\s\((.+)\)", user_profile_folder["name"]
        )
        if user_name_match_result:
            user_name = user_name_match_result.group(1)
            if user_name not in all_user_names:
                delete_object(
                    project_conn,
                    user_profile_folder["id"],
                    f'User profile folder - {user_profile_folder["name"]}',
                    MSTR_OBJECTTYPE_FOLDER,
                )


def delete_client_users(proj_instance_conn, exclude_client_ids):
    """ Deletes users part of the "Everyone" user group except client users(based on exclude_client_ids passed) and system administrators """
    all_user_details = get_member_details_under_group(proj_instance_conn, "Everyone")
    client_user_details = []
    if exclude_client_ids:
        for client_id in exclude_client_ids:
            client_user_details.extend(
                get_member_details_under_group(proj_instance_conn, client_id)
            )

    system_admin_user_details = get_member_details_under_group(
        proj_instance_conn, "System Administrators"
    )

    users_not_to_be_deleted = set(
        user["name"] for user in (client_user_details + system_admin_user_details)
    )

    for user in all_user_details:
        if user["name"] not in users_not_to_be_deleted:
            delete_object(
                proj_instance_conn,
                user["id"],
                f'User - {user["name"]}',
                MSTR_OBJECTTYPE_USER,
            )

    print(
        f"Deleted all users under 'Everyone' group except the ones under {', '.join(exclude_client_ids) + ' and ' if exclude_client_ids else ''}System Administrators"
    )


def delete_client_user_groups(proj_instance_conn, exclude_client_ids, mstr_info):
    """ Deletes user groups under 'Clients' user group except the user groups for the exclude_client_ids passed """
    if exclude_client_ids is None:
        exclude_client_ids = []

    client_user_groups = get_member_details_under_group(proj_instance_conn, "Clients")
    for user_group in client_user_groups:
        if user_group["name"] not in exclude_client_ids:
            delete_object(
                proj_instance_conn,
                user_group["id"],
                f'User group - {user_group["name"]}',
                MSTR_OBJECTTYPE_USERGROUP,
            )


def delete_all_subscriptions(mstr_info):
    """ Deletes all subscriptions for the project passed as part of the 'mstr_info' """
    delete_all_subscriptions_script = DELETE_ALL_SUBSCRIPTIONS_TEMPLATE.substitute(
        project_name=mstr_info["mstr_project_name"]
    )
    mstr_utility.execute_cmd_manager_script(mstr_info, delete_all_subscriptions_script)
    print(
        f"Deleted all subscriptions for the project - {mstr_info['mstr_project_name']}"
    )


def get_all_schedule_names_list(mstr_info):
    """ Returns a list of names of all schedules in the project source """
    schedule_names_list = [
        schedule["Name"]
        for schedule in mstr_utility.run_command_manager(
            mstr_info, LIST_ALL_SCHEDULES_SCRIPT
        )
    ]

    return schedule_names_list


def get_properties_for_all_schedules(mstr_info, schedule_names_list):
    """ Returns a list of objects containing properties for all schedules """
    properties_for_all_schedules = []
    for schedule in schedule_names_list:
        list_schedule_properties_script = LIST_SCHEDULE_PROPERTIES_TEMPLATE.substitute(
            schedule_name=schedule
        )
        schedule_props = next(
            mstr_utility.run_command_manager(mstr_info, list_schedule_properties_script)
        )
        properties_for_all_schedules.append(schedule_props)

    return properties_for_all_schedules


def delete_all_schedules(mstr_info):
    """ Deletes all schedules except the ones owned by Administrator """
    print("Deleting schedules ...")
    schedule_names_list = get_all_schedule_names_list(mstr_info)
    schedule_properties_list = get_properties_for_all_schedules(
        mstr_info, schedule_names_list
    )

    for schedule in schedule_properties_list:
        if schedule["Owner"] != "Administrator(Administrator)":
            delete_schedule_script = DELETE_SCHEDULE_TEMPLATE.substitute(
                schedule_name=schedule["Name"]
            )
            mstr_utility.execute_cmd_manager_script(mstr_info, delete_schedule_script)

    print("Deleted all schedules except the ones owned by Administrator(Administrator)")


def delete_object(project_instance_conn, object_id, object_name, object_type_id):
    """ Deletes MSTR objects but handles the issue of the object having dependents by skipping the object instead of failing"""
    try:
        mstr_utility.execute_delete_api(
            project_instance_conn, f"/objects/{object_id}?type={object_type_id}", None
        )
        print(f"Object deleted: {object_name}")
    except Exception as e:
        error_msg = str(e)  # Reads the message from the Exception object as a string
        error_msg_bytes = ast.literal_eval(
            error_msg
        )  # stores in the variable as bytes literal
        error_dict = ast.literal_eval(
            error_msg_bytes.decode("UTF-8")
        )  # Decodes the bytes as string and then evalutes to dictionary
        if error_dict["iServerCode"] == -2147217387:
            # Error code: DSSCOM_E_DELETE_DEPOBJ(-2147217387) Ref. - https://lw.microstrategy.com/msdz/MSDL/GARelease_Current/docs/ReferenceFiles/reference/com/microstrategy/utils/localization/WebAPIErrorCodes.html
            print(
                f"Object skipped: {object_name} not deleted because objects are dependent on it. Error: {error_msg}"
            )
        else:
            raise


def delete_client_dbconnections(project_instance_conn, mstr_info, exclude_client_ids):
    """ Deletes DB Connections for clients except the ones which contain 'exclude_client_ids' passed or 'Default' or 'STATISTICS' keyword in their names """
    if exclude_client_ids is None:
        exclude_client_ids = []

    dbconns_not_to_be_deleted = (
        exclude_client_ids + DB_CONNECTIONS_EXCLUDED_FROM_DELETION
    )

    for db_connection in mstr_utility.run_command_manager(
        mstr_info, LIST_ALL_DB_CONNECTIONS_SCRIPT
    ):
        if all(
            excluded_db_conn_keywords not in db_connection["Database Connection"]
            for excluded_db_conn_keywords in dbconns_not_to_be_deleted
        ):
            list_dbconn_props_script = LIST_DB_CONNECTION_PROPERTIES_TEMPLATE.substitute(
                dbconnection_name=db_connection["Database Connection"]
            )
            dbconn_props_row = next(
                mstr_utility.run_command_manager(mstr_info, list_dbconn_props_script)
            )
            dbconnection_id = dbconn_props_row["ID"]
            delete_object(
                project_instance_conn,
                dbconnection_id,
                f'DBConnection - {db_connection["Database Connection"]}',
                MSTR_OBJECTTYPE_DBCONNECTION,
            )


def delete_client_dblogins(proj_instance_conn, exclude_client_ids):
    """ Deletes DB Logins for clients except the ones which contain 'exclude_client_ids' passed or 'Default' or 'STATISTICS' keyword in their names """
    all_dblogins = get_list_of_objects(proj_instance_conn, "dbLogins")

    if exclude_client_ids is None:
        exclude_client_ids = []

    dblogins_not_to_be_deleted = exclude_client_ids + DB_LOGINS_EXCLUDED_FROM_DELETION

    for dblogin in all_dblogins:
        if all(
            excluded_dblogin_keyword not in dblogin["name"]
            for excluded_dblogin_keyword in dblogins_not_to_be_deleted
        ):
            delete_object(
                proj_instance_conn,
                dblogin["id"],
                f'DBLogin - {dblogin["name"]}',
                MSTR_OBJECTTYPE_DBLOGIN,
            )


def delete_client_sections_from_odbcfile(odbc_file_path, exclude_client_ids):
    """ Delete sections from ODBC file for which the section names start with 'OPA_WH' which are client specific except for the ones which contain 'exclude_client_ids' passed """
    config_parser = SafeConfigParser(strict=False)
    config_parser.optionxform = str
    config_parser.read(odbc_file_path)

    if exclude_client_ids is None:
        exclude_client_ids = []

    for section in config_parser.sections():
        if section.startswith("OPA_WH") and all(
            client_id not in section for client_id in exclude_client_ids
        ):
            if config_parser.remove_section(section):
                print(f"Deleted section: {section}")
            else:
                print(f"{section} could not be deleted from ODBC file.")

    config_parser = delete_unused_client_datasource_options_from_odbc(config_parser)

    with open(odbc_file_path, "w") as configfile:
        config_parser.write(configfile, space_around_delimiters=False)


def delete_unused_client_datasource_options_from_odbc(odbc_parser):
    """ Delete options from "ODBC Data Sources" section in ODBC file for which the option names start with 'OPA_WH' which are client specific and do not have a config. section in the odbc.ini file """

    for option in odbc_parser.options(ODBC_DATA_SOURCES_SECTION_IN_ODBCFILE):
        if option.startswith("OPA_WH") and option not in odbc_parser.sections():
            if odbc_parser.remove_option(ODBC_DATA_SOURCES_SECTION_IN_ODBCFILE, option):
                print(f"Deleted option from 'ODBC Data Sources' section: {option}")
            else:
                print(
                    f"'{option}' could not be deleted from 'ODBC Data Sources' section in ODBC file."
                )

    return odbc_parser


def set_dbconnecton_for_dbinstance(mstr_info, dbinstance_name, dbconnection_name):
    set_default_dbconn_for_dbinstance_script = ALTER_DB_CONN_FOR_DB_INSTANCE_TEMPLATE.substitute(
        dbinstance_name=dbinstance_name, dbconnection_name=dbconnection_name
    )
    mstr_utility.execute_cmd_manager_script(
        mstr_info, set_default_dbconn_for_dbinstance_script
    )


def set_dblogin_for_dbconnection(mstr_info, dbconnection_name, dblogin_name):
    set_default_dblogin_for_dbconn_script = ALTER_DEFAULT_DB_LOGIN_FOR_DB_CONN_TEMPLATE.substitute(
        dbconnection_name=dbconnection_name, dblogin_name=dblogin_name
    )
    mstr_utility.execute_cmd_manager_script(
        mstr_info, set_default_dblogin_for_dbconn_script
    )


def set_config_for_dbinstance(
    mstr_info, dbinstance_name, dbconnection_name, dblogin_name
):
    set_dbconnecton_for_dbinstance(mstr_info, dbinstance_name, dbconnection_name)
    set_dblogin_for_dbconnection(mstr_info, dbconnection_name, dblogin_name)


def set_default_settings_for_OPA_dbinstances(mstr_info):
    set_config_for_dbinstance(
        mstr_info,
        "OPA OADW Database Instance",
        "H_Default OADW Database Connection",
        "H_Default_OADW Login",
    )
    set_config_for_dbinstance(
        mstr_info,
        "OPA RW Database Instance",
        "H_Default_RW Database Connection",
        "H_Default_RW_Login",
    )
    set_config_for_dbinstance(
        mstr_info,
        "OPA XQ Database Instance",
        "H_Default XQ Database Connection",
        "H_Default_RW_Login",
    )


def restart_iservers(mstr_info):
    mstr_utility.restart_all_iservers(
        mstr_info["default_projectsource"],
        mstr_info["mstr_username"],
        mstr_info["mstr_password"],
    )
    print("Restarted all the iServers.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Create a clean MSTR project by deleting all unnecesary client folders, users, subscriptions and schedules as per requirement"
    )
    parser.add_argument(
        "--exclude_client_ids",
        help="Case-sensitive client identifiers e.g. 'H123456'. Multiple client IDs are supported and can be specified like 'H000000' 'H592196' 'H704847' (space-separated values). It is used to identify the client(s) for which the configurations should not be deleted.",
        nargs="*",
        type=str,
    )
    parser.add_argument(
        "--exclude_client_names",
        help="Client name(s) which will be used to identify client report folders. Multiple client names are supported and can be specified like 'Ascension' 'Blue Cross NC' 'NYU's. It is used to identify which client folders should not be deleted.",
        nargs="*",
        type=str,
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
        "--delete_subscriptions", action="store_true", help="Deletes all subscriptions"
    )
    parser.add_argument(
        "--delete_schedules",
        action="store_true",
        help="Deletes all schedules except ones owned by System Administrators",
    )

    args = parser.parse_args()

    mstr_password = mstr_utility.get_parameter(args.mstr_password_key)

    proj_instance_conn = mstr_utility.get_mstr_connection(
        args.mstr_username, mstr_password
    )
    proj_instance_conn.connect()

    with open(
        os.path.join(sys.path[0], "general_config.json"), "r"
    ) as general_conf_file:
        general_config = json.load(general_conf_file)

    mstr_info = {}
    mstr_info["default_projectsource"] = general_config["default_projectsource"]
    mstr_info["mstr_project_name"] = args.mstr_project_name
    mstr_info["mstr_username"] = args.mstr_username
    mstr_info["mstr_password"] = mstr_password

    if not args.exclude_client_ids and not args.exclude_client_names:
        delete_all_subscriptions(mstr_info)
        delete_all_schedules(mstr_info)
    else:
        if args.delete_subscriptions:
            delete_all_subscriptions(mstr_info)
        if args.delete_schedules:
            delete_all_schedules(mstr_info)

    delete_client_users(proj_instance_conn, args.exclude_client_ids)

    delete_client_user_groups(proj_instance_conn, args.exclude_client_ids, mstr_info)

    delete_client_dbconnections(proj_instance_conn, mstr_info, args.exclude_client_ids)

    delete_client_dblogins(proj_instance_conn, args.exclude_client_ids)

    delete_client_sections_from_odbcfile(
        general_config["odbc_file"], args.exclude_client_ids
    )

    set_default_settings_for_OPA_dbinstances(mstr_info)

    # The final list of user details after all the required deletions to help delete user profile folders accordingly
    existing_user_details = get_member_details_under_group(
        proj_instance_conn, "Everyone"
    )
    proj_instance_conn.close()

    project_conn = mstr_utility.get_mstr_project_connection(
        args.mstr_username, mstr_password, args.mstr_project_name
    )
    project_conn.connect()

    delete_user_profile_folders(project_conn, existing_user_details)

    report_folders_obj_list = get_list_of_objects(
        project_conn, f"folders/preDefined/{MSTR_FOLDERNAME_PUBLICREPORTS}?limit=-1"
    )
    report_folders = [obj["name"] for obj in report_folders_obj_list]
    clients_to_be_deleted = get_clients_with_folders(
        report_folders, args.exclude_client_names
    )
    print(f"Clients for which report folders will be deleted: {clients_to_be_deleted}")
    delete_client_folders(project_conn, clients_to_be_deleted)

    project_conn.close()

    # iserver restart is required to reflect change in dbconnection and dbogin settings for a db instance
    restart_iservers(mstr_info)
    print("Project cleaning completed")
