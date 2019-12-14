#!/usr/bin/env python3
import os
import sys
import argparse
import subprocess
import datetime
import mysql_utility
import mstr_utility
import pymysql.cursors
import time
from shutil import copyfile
import json
from configparser import SafeConfigParser
import fileinput
import socket
import csv

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


def import_file_to_database(host_name, database_name, port, user_name, password, metadata_file_path):
    mysql_params = f'mysql -h {host_name} -u {user_name} -p{password} {database_name} < {metadata_file_path}'
    try:
        mysql_output = subprocess.check_output(
                mysql_params, shell=True
            ).decode("utf-8")
        print(f"Successfully imported {metadata_file_path} to {database_name}")
    except subprocess.CalledProcessError as mysql_output:
        print("error code", mysql_output.returncode, mysql_output.output)



def update_odbc_database_entry(odbc_file, odbc_entry, database_name):
    get_file_backup(odbc_file)
    parser = SafeConfigParser(strict=False)
    parser.optionxform = str
    parser.read(odbc_file)
    parser.set(odbc_entry, 'DATABASE', database_name)
    with open(odbc_file, 'w') as configfile:
        parser.write(configfile,space_around_delimiters=False)

def get_odbc_database_name(odbc_file,odbc_entry):
    parser = SafeConfigParser(strict=False)
    parser.optionxform = str
    parser.read(odbc_file)
    old_database_name = parser.get(odbc_entry, 'DATABASE')
    return old_database_name


def get_file_backup(src):
    dst = src + '_bak_' + '{:%Y%m%d%H%M%S}'.format(datetime.datetime.now())
    copyfile(src, dst)
    return dst

def user_exists(connection, user_name):
    obj = mstr_utility.execute_get_api(connection, "/users")
    return any(user['abbreviation'] == user_name for user in obj)

def create_user(connection, user_name, password, group_id):
    user_json = {}
    user_json["username"] = user_name
    user_json["fullName"] = user_name
    user_json["password"] = password
    user_json["requireNewPassword"] = "false"
    user_json["memberships"] = [group_id]
    mstr_utility.execute_post_api(connection, "/users", user_json)

def substitute_in_template(file,searchExp,replaceExp):
    for line in fileinput.input(file, inplace=1):
        if searchExp in line:
            line = line.replace(searchExp,replaceExp)
        sys.stdout.write(line)

def updateProjectConfig(configs,projectname, intelligentcubefilelocation, webservermacro, cachefilelocation):
    substitute_in_template(configs,"[projectname]",'"'+projectname+'"')
    substitute_in_template(configs,"[intelligentcubefilelocation]",'"'+intelligentcubefilelocation+'"')
    substitute_in_template(configs,"[webservermacro]",'"'+webservermacro+'"')
    substitute_in_template(configs,"[cachefilelocation]",'"'+cachefilelocation+'"')

def fix_metadata_file(input_file, output_file):
    iconv_params = f'iconv -f UTF-16LE -t UTF-8 {input_file} > {output_file}'
    iconv_output = subprocess.check_output(iconv_params, shell=True).decode("utf-8")
    print(iconv_output)
    sed_params = "sed -i 's/DEFINER=[^*]*\*/\*/g' " + output_file
    sed_output = subprocess.check_output(sed_params, shell=True).decode("utf-8")
    print(sed_output)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Provide MSTR environment details and project configurations")
    parser.add_argument('--mstr_project_name', type=str, help='MicroStrategy project name')
    parser.add_argument('--mysql_host', type=str, help='AWS Mysql Hostname')
    parser.add_argument('--mysql_port', type=int, help='AWS Mysql port')
    parser.add_argument('--mysql_metadata_database', type=str, help='AWS Mysql Database')
    parser.add_argument('--mysql_username', type=str, help='Mysql UserName')
    parser.add_argument('--mysql_password_key', type=str, help='Mysql Pasword')
    parser.add_argument('--mstr_username', type=str, help='Microstrategy Username')
    parser.add_argument('--mstr_password_key', type=str, help='Microstrategy Password')
    parser.add_argument('--opa_username', type=str, help='OPA Master Username which used for backup project')
    parser.add_argument('--opa_password_key', type=str, help='OPA Master Password which used for backup project')
    parser.add_argument('--metadata_s3_uri', type=str, help='Metadata sql dump file path')
    args = parser.parse_args()

    try:
        print("Step 0/11: Get configs")
        mstr_server_name = socket.gethostname()
        mstr_instance_id = mstr_utility.get_instance(mstr_server_name)
        mysql_password = mstr_utility.get_parameter(args.mysql_password_key)
        mstr_password = mstr_utility.get_parameter(args.mstr_password_key)
        opa_password = mstr_utility.get_parameter(args.opa_password_key)
        old_database_name = get_odbc_database_name(odbc_file, odbc_entry)

        print("Step 1/11: Sync metadata from S3 to EC2")
        #mstr_utility.sync_folders(mstr_instance_id,args.metadata_s3_uri,'/tmp/')
        fixed_file = '/tmp/metadata_file.sql'
        fix_metadata_file('/tmp/prod_metadata_backup.sql', fixed_file)

        # Create a new project source
        print("Step 2/11: Create Project Source using Response file to access the iServer through Command Manager")
        mstr_utility.add_projectsource(projectsource_template_ini, mstr_server_name)

        print("Set 3/11: Stop i-server")
        get_cluster_servers_script = 'LIST ALL SERVERS IN CLUSTER;'
        results_csv = mstr_utility.get_cmd_mngr_script_result_csv(mstr_server_name, args.mstr_username, mstr_password, get_cluster_servers_script)
        with open(results_csv, newline='') as csvfile:
            iservers = csv.DictReader(csvfile)
            for iserver in iservers:
                mstr_utility.add_projectsource(projectsource_template_ini, iserver['Name'])
                mstr_utility.stop_iserver(iserver['Name'], mstr_password)

        # Restore metadata file to new dB
        print("Step 4/11: Restore On-Prem Metadata DB to a new DB on MySQL ")
        db_handle = mysql_utility.get_db_connection_handle(args.mysql_host, 'mysql', args.mysql_port, args.mysql_username, mysql_password)
        mysql_utility.create_if_not_exist_database(db_handle, args.mysql_metadata_database.lower())
        import_file_to_database(args.mysql_host, args.mysql_metadata_database.lower(), args.mysql_port, args.mysql_username, mysql_password, fixed_file)

        # Point Metadata ODBC entry to new dB
        print("Step 5/11: Update Metadata ODBC entry to point to this new DB")
        update_odbc_database_entry(odbc_file, odbc_entry, args.mysql_metadata_database.lower())

        # Start iServer
        print("Step 6/11: Start i-server")
        with open(results_csv, newline='') as csvfile:
            iservers = csv.DictReader(csvfile)
            for iserver in iservers:
                mstr_utility.start_iserver(iserver['Name'], mstr_password)

        #mstr_utility.add_iserver_definition(iserver_ini, args.mstr_username, args.mstr_password_key)

        # Register Project in iServer
        print("Step 7/11: Register OPA project on iServer")
        with open(results_csv, newline='') as csvfile:
            iservers = csv.DictReader(csvfile)
            for iserver in iservers:
                mstr_utility.register_project(iserver['Name'], args.opa_username, opa_password, args.mstr_project_name)
        time.sleep(60)
        # Existing AWS mstr user will be lost because of metadata copy. Hence it should be created.
        conn = mstr_utility.get_mstr_connection(args.opa_username, opa_password)
        conn.connect()
        time.sleep(60)
        print("Step 8/11: Create aws mstr admin account as the existing account will not be available because of Metadata SWAP")
        if user_exists(conn, args.mstr_username):
            print("user already exists")
        else:
            print("creating user")
            create_user(conn, args.mstr_username, mstr_password, mstr_admin_group_id)

 

        #Import Project Config
        print("Step 10/11: Update OPA project configuration using command manager script generated from back-up process")
        #updateProjectConfig(project_config_file,args.mstr_project_name, cube_file_location, web_server_macro, cache_file_location)
        mstr_utility.execute_command(mstr_server_name, args.mstr_username, mstr_password, '/tmp/'+project_config_file)

        #Refresh schema
        print("Step 11/11: Refresh schema")
        with open(results_csv, newline='') as csvfile:
            iservers = csv.DictReader(csvfile)
            for iserver in iservers:
                mstr_utility.refresh_schema(iserver['Name'], args.mstr_username, mstr_password,args.mstr_project_name)
                mstr_utility.stop_iserver(iserver['Name'], mstr_password)
                mstr_utility.start_iserver(iserver['Name'], mstr_password)

    except Exception as e:
        print("Failure: Reverting odbc setting to previous db")
        update_odbc_database_entry(odbc_file, odbc_entry, old_database_name)

        with open(results_csv, newline='') as csvfile:
            iservers = csv.DictReader(csvfile)
            for iserver in iservers:
                mstr_utility.stop_iserver(iserver['Name'], mstr_password)
                mstr_utility.start_iserver(iserver['Name'], mstr_password)

        print('An error occurred while executing the script:'+ e)
        raise e
