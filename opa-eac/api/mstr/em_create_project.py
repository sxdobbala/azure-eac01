#!/usr/bin/env python3
import os
import sys
import argparse
import subprocess
import logging
import datetime
import mstr_utility
import mysql_utility
import time
from shutil import copyfile
import json
from configparser import SafeConfigParser
import socket

#Getting configs
with open(os.path.join(sys.path[0], "general_config.json"), "r") as f:
    general_config = json.load(f)

with open(os.path.join(sys.path[0], "project_config.json"), "r") as f:
    project_config = json.load(f)

#Project config
cube_file_location = project_config['cube_file_location']
web_server_macro = project_config['web_server_macro']
cache_file_location = project_config['cache_file_location']

project_config_file = project_config['project_config_file']
package_file = general_config['package_file']
odbc_file = general_config['odbc_file']
odbc_entry = general_config['metadata_odbc_entry']
mstr_admin_group_id = project_config['mstr_admin_group_id']
projectsource_template_ini = general_config['projectsource_template_ini']
iserver_ini = general_config['iserver_def_template_ini']

def em_create_repository(template_em_response_ini, dsn_user, dsn_pwd, dsn_host, dsn_database, dsn_port, dsn_prefix):
    db_handle = mysql_utility.get_db_connection_handle(dsn_host, 'mysql', dsn_port, dsn_user, dsn_pwd)
    database_exists = mysql_utility.check_if_database_exist(db_handle, dsn_database)

    print("Updating Statistics ODBC entry to use new database")
    odbc_file = '/opt/mstr/MicroStrategy/odbc.ini'
    odbc_entry = 'STATISTICS'
    mstr_utility.update_odbc_database_entry(odbc_file, odbc_entry, dsn_database.lower())

    if database_exists:
        print(f"Database {dsn_database} already exists. New Enterprise Manager repository won't be created.")
        return

    print(f"Creating new MySQL database: {dsn_database}")
    mysql_utility.create_if_not_exist_database(db_handle, dsn_database.lower())


    print("Creating new Enterprise Manager repository")

    # Create response ini file based on the template
    parser = SafeConfigParser()
    parser.optionxform = str
    parser.read(template_em_response_ini)
    parser.set('Repository', 'UserNameStats', dsn_user)
    parser.set('Repository', 'UserPwdStats', dsn_pwd)
    parser.set('Repository', 'StatisticsPrefix', dsn_prefix)
    temp_em_response_ini = '/tmp/em_repository_response.ini'
    with open(temp_em_response_ini, 'w') as inifile:
        parser.write(inifile, space_around_delimiters=False)

    # Run MicroStrategy Configuration Wizard
    mstr_utility.run_config_wizard(temp_em_response_ini)

    # Delete response file
    os.remove(temp_em_response_ini)



def em_create_project(template_em_response_ini, dss_user, dss_pwd, dsn_user, dsn_pwd, dsn_prefix):
    conn = mstr_utility.get_mstr_connection(dss_user, dss_pwd)
    conn.connect()

    if project_exists(conn, 'Enterprise Manager'):
        print("Enterprise Manager project already exists. Hence overwriting the project")
        #return

    # Create response ini file based on the template
    parser = SafeConfigParser()
    parser.optionxform = str
    parser.read(template_em_response_ini)
    parser.set('EMProjectHeader', 'EMProjectDSSUser', dss_user)
    parser.set('EMProjectHeader', 'EMProjectDSSPwd', dss_pwd)
    parser.set('EMProjectHeader', 'EMProjectDSNUserName', dsn_user)
    parser.set('EMProjectHeader', 'EMProjectDSNUserPwd', dsn_pwd)
    parser.set('EMProjectHeader', 'EMProjectDSNPrefix', dsn_prefix)
    temp_em_response_ini = '/tmp/em_project_response.ini'
    with open(temp_em_response_ini, 'w') as inifile:
        parser.write(inifile, space_around_delimiters=False)

    # Run MicroStrategy Configuration Wizard
    mstr_utility.run_config_wizard(temp_em_response_ini)

    # Delete response file
    os.remove(temp_em_response_ini)

def em_configure(mstr_project_source, mstr_user, mstr_pwd, mstr_project_name):
    print("Configuring statistics for Enterprise Manager project")
    mstr_utility.em_configure_project_statistics(mstr_project_source, mstr_user, mstr_pwd, 'Enterprise Manager')
    print("Configuring statistics for Performance Analytics project")
    mstr_utility.em_configure_project_statistics(mstr_project_source, mstr_user, mstr_pwd, mstr_project_name)
    print("Delete existing data loads for  Enterprise Manager")
    mstr_utility.delete_existing_em_loads(mstr_project_source, mstr_user, mstr_pwd)
    print("Trying to connect to Enterprise Manager")
    mstr_utility.em_connect(mstr_project_source, mstr_user, mstr_pwd)
    print("Start monitoring for Enterprise Manager")
    mstr_utility.em_start_monitoring(mstr_project_source, mstr_user, mstr_pwd)
    print("Creating data load for Enterprise Manager")
    mstr_utility.em_create_data_load(mstr_project_source, mstr_user, mstr_pwd)
    #print("Executing data load for Enterprise Manager")
    #mstr_utility.em_execute_data_load(mstr_project_source, mstr_user, mstr_pwd)

def project_exists(connection, project_name):
    obj = mstr_utility.execute_get_api(connection, "/projects")
    return any(project['name'] == project_name for project in obj)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Specify Enterprise Manager project settings")

    parser.add_argument('--mstr_project_name', type=str, help='MicroStrategy project name')
    parser.add_argument('--mysql_host', type=str, help='AWS Mysql Hostname')
    parser.add_argument('--mysql_port', type=int, help='AWS Mysql port')
    parser.add_argument('--mysql_stats_database', type=str, help='AWS Mysql Statistics Database')
    parser.add_argument('--mysql_username', type=str, help='Mysql UserName')
    parser.add_argument('--mysql_password_key', type=str, help='Mysql Pasword')
    parser.add_argument('--mstr_username', type=str, help='Microstrategy Username')
    parser.add_argument('--mstr_password_key', type=str, help='Microstrategy Password')

    args = parser.parse_args()
    template_em_project_response = os.path.join(sys.path[0], 'em_project_response.ini')
    template_em_repository_response = os.path.join(sys.path[0], 'em_repository_response.ini')

    try:
        mysql_password = mstr_utility.get_parameter(args.mysql_password_key)
        mstr_password = mstr_utility.get_parameter(args.mstr_password_key)
        mstr_server_name = socket.gethostname()

        # Create a new project source
        mstr_utility.add_projectsource(projectsource_template_ini, mstr_server_name)

        print("Creating Enterprise Manager repository")
        dsn_prefix = ""
        stats_db = args.mysql_stats_database


        em_create_repository(template_em_repository_response,args.mysql_username, mysql_password, args.mysql_host, stats_db.lower(), args.mysql_port, dsn_prefix)


        print("Creating Enterprise Manager project")
        em_create_project(template_em_project_response, args.mstr_username, mstr_password, args.mysql_username, mysql_password, dsn_prefix)


        print("Configuring Enterprise Manager project")
        em_configure(mstr_server_name, args.mstr_username, mstr_password, args.mstr_project_name)

        #Restart iServer
        mstr_utility.restart_all_iservers(mstr_server_name, args.mstr_username, mstr_password)
        print("Restarted all the iServers.")


    except Exception as e:
        print('An error occurred while executing the script:'+ e)
        raise e
