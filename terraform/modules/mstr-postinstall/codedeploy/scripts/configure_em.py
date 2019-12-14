#!/usr/bin/env python3

"""Post Install Script to setup Enterprise Manager"""
import argparse
from string import Template
import sys
mstr_infra_path = "/opt/opa/install/mstr-infra/mstr"
sys.path.append(mstr_infra_path)
import mstr_utility
from update_proj_memory import get_ssm_parameter, get_mstr_command_manager_result_file
from ec2_metadata import ec2_metadata
import socket
import re
import time


CREATE_DATA_LOAD_TEMPLATE = Template(
    'CREATE DATA LOAD "DataLoad_Local" FOR\
    $data_load_env_and_project\
    DO ACTION UPDATEWAREHOUSE CLOSESESSIONS REPOPULATETABLES UPDATESTATS UPDATEOBJECTDELETIONS\
    BEGIN DATE "03/30/2017 09:00:00 +0400"\
    FREQUENCY WEEKLY ON MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY AT 06:00:00 ENABLED\
    IN ENTERPRISE MANAGER "localhost" IN PORT 9999;'
)
START_MONITORING_TEMPLATE = Template(
    'START MONITORING SERVER "$hostname" IN PORT 34952\
    USING USERNAME "$user_name" PASSWORD "$password"\
    FOR ENTERPRISE MANAGER "localhost" IN PORT 9999;'
)
LIST_PROPERTIES_FOR_ENTERPRISE_MANAGER_SCRIPT = (
    'LIST PROPERTIES FOR ENTERPRISE MANAGER "localhost" IN PORT 9999;'
)
STOP_LOCALHOST_MONITORING_SCRIPT = (
    'STOP MONITORING SERVER "localhost" IN ENTERPRISE MANAGER "localhost" IN PORT 9999;'
)


def configure_project_statistics(mstr_info, project_name):
    """ Update statistics config in Project Configuration"""
    mstr_utility.em_configure_project_statistics(
        mstr_info["default_projectsource"],
        mstr_info["mstr_username"],
        mstr_info["mstr_password"],
        project_name,
    )


def check_monitoring_for_server(mstr_info, server_name):
    prop_results_file = get_mstr_command_manager_result_file(
        mstr_info, LIST_PROPERTIES_FOR_ENTERPRISE_MANAGER_SCRIPT
    )

    with open(prop_results_file) as props_file:
        props_data = props_file.read()

    monitored_server = re.search(
        r"Monitored Environments\n\tMachine Name = ([a-zA-z0-9-]+)", props_data
    )
    return monitored_server.group(1) == server_name


def em_stop_localhost_monitoring(mstr_info):
    mstr_utility.execute_cmd_mngr_script(
        mstr_info["default_projectsource"],
        mstr_info["mstr_username"],
        mstr_info["mstr_password"],
        STOP_LOCALHOST_MONITORING_SCRIPT,
    )
    print("Stopped monitoring on server 'localhost'")


def em_start_monitoring(mstr_info):
    """ Setup Enterprise Manager Monitoring """
    command = START_MONITORING_TEMPLATE.substitute(
        hostname=mstr_info["mstr_server_name"],
        user_name=mstr_info["mstr_username"],
        password=mstr_info["mstr_password"],
    )
    mstr_utility.execute_cmd_mngr_script(
        mstr_info["default_projectsource"],
        mstr_info["mstr_username"],
        mstr_info["mstr_password"],
        command,
    )
    print(f'Started monitoring on server: {mstr_info["mstr_server_name"]}')


def em_create_data_load(mstr_info, data_source_projects):
    """ Creates Data Load for a project """
    data_load_env_and_project = ", ".join(
        'ENVIRONMENT "{0}" AND PROJECT "{1}"'.format(
            mstr_info["mstr_server_name"], project_name
        )
        for project_name in data_source_projects
    )
    command = CREATE_DATA_LOAD_TEMPLATE.substitute(
        data_load_env_and_project=data_load_env_and_project
    )
    mstr_utility.execute_cmd_mngr_script(
        mstr_info["default_projectsource"],
        mstr_info["mstr_username"],
        mstr_info["mstr_password"],
        command,
    )


def delete_existing_em_loads(mstr_info):
    """ Deleting Data loads if it already exists """
    mstr_utility.delete_existing_em_loads(
        mstr_info["default_projectsource"],
        mstr_info["mstr_username"],
        mstr_info["mstr_password"],
    )


def update_webservermacro(mstr_info):
    """ Updating web server macro  """
    command = f'ALTER PROJECT CONFIGURATION WEBSERVERMACRO "{hostname(mstr_info["env_prefix"])}{mstr_info["app_elb_path"]}/MicroStrategy/servlet/mstrWeb" IN PROJECT "Performance Analytics";'
    mstr_utility.execute_cmd_mngr_script(
        mstr_info["default_projectsource"],
        mstr_info["mstr_username"],
        mstr_info["mstr_password"],
        command,
    )


def hostname(env):
    switcher = {
        "prod": "https://cloud.performanceanalytics.optum.com/",
        "stage": "https://stagecloud.performanceanalytics.optum.com/",
        "qa": "https://qacloud.performanceanalytics.optum.com/",
        "dev": "https://devcloud.performanceanalytics.optum.com/",
    }
    return switcher.get(env, "Invalid Environment Name")


def alter_mstr_db_login(mstr_info, statistics_login_name):
    """ Update Password for Statistics DB Login """
    mstr_utility.alter_mstr_db_login(
        mstr_info["default_projectsource"],
        statistics_login_name,
        mstr_info["mysql_username"],
        mstr_info["mysql_password"],
        mstr_info["mstr_username"],
        mstr_info["mstr_password"],
    )


def project_exists(mstr_info, connection, project_name):
    connection.connect()
    projects = mstr_utility.execute_get_api(connection, "/projects")
    return any(project["name"] == project_name for project in projects)
    connection.close()


if __name__ == "__main__":
    default_project_source = "mstr_metadata"

    parser = argparse.ArgumentParser(
        description="Post Install Script - Enterprise Manager configuration"
    )
    parser.add_argument(
        "--mstr_username", help="MicroStrategy UserName", required="true"
    )
    parser.add_argument(
        "--mstr_password_key",
        help="Microstrategy password ssm store location",
        required="true",
    )
    parser.add_argument("--mysql_username", help="Mysql UserName", required="true")
    parser.add_argument(
        "--mysql_password_key",
        help="Mysql password ssm store location",
        required="true",
    )
    parser.add_argument("--env_prefix", help="Environment Prefix", required="true")
    parser.add_argument("--app_elb_path", help="App Elb Path", required="true")
    args = parser.parse_args()

    mstr_info = {}
    mstr_info["mstr_server_name"] = socket.gethostname()
    mstr_info["default_projectsource"] = default_project_source
    mstr_info["mstr_username"] = args.mstr_username
    mstr_info["mstr_password"] = get_ssm_parameter(
        args.mstr_password_key, ec2_metadata.region
    )
    mstr_info["mysql_username"] = args.mysql_username
    mstr_info["mysql_password"] = get_ssm_parameter(
        args.mysql_password_key, ec2_metadata.region
    )
    mstr_info["env_prefix"] = args.env_prefix
    mstr_info["app_elb_path"] = args.app_elb_path

    conn = mstr_utility.get_mstr_connection(
        mstr_info["mstr_username"], mstr_info["mstr_password"]
    )

    data_load_source_projects = []

    time.sleep(60)

    if project_exists(mstr_info, conn, "Performance Analytics"):
        data_load_source_projects.append("Performance Analytics")

        update_webservermacro(mstr_info)

        alter_mstr_db_login(mstr_info, "STATISTICS")

        configure_project_statistics(mstr_info, "Performance Analytics")

    if project_exists(mstr_info, conn, "Enterprise Manager"):
        data_load_source_projects.append("Enterprise Manager")

        configure_project_statistics(mstr_info, "Enterprise Manager")

        if check_monitoring_for_server(mstr_info, "localhost"):
            em_stop_localhost_monitoring(mstr_info)
            em_start_monitoring(mstr_info)

        # MSTR on AWS should have already configured monitoring on <env. name>
        # but we do need to re-configure data loads

        delete_existing_em_loads(mstr_info)
        em_create_data_load(mstr_info, data_load_source_projects)
