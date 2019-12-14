import os
import sys
import argparse
import subprocess
import datetime
import time
import requests
import json
import csv
import socket
import pexpect
import boto3
import secrets
import string
from mstrio import microstrategy
from string import Template
from configparser import SafeConfigParser
from shutil import copyfile, copy2

ALTER_DB_LOGIN_TEMPLATE = Template(
    'ALTER DBLOGIN "$login_name" LOGIN "$username" PASSWORD "$password";\n'
)

SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))

#Getting configs
with open(os.path.join(SCRIPTS_DIR, "general_config.json"), "r") as f:
    generalconfig = json.load(f)

mstr_cntrl_util_cmd = generalconfig['mstr_cntrl_util_cmd']
command_mngr_path = generalconfig['command_mngr_path']

def run_iserver_command(task):
    mstr_cntrl_util_output = subprocess.check_output(
        mstr_cntrl_util_cmd + task, shell=True
    ).decode("utf-8")
    return mstr_cntrl_util_output

def run_iserver_command_on_host(task, host):
    host_switch = '-m '+ host + ' '
    mstr_cntrl_util_output = subprocess.check_output(
        mstr_cntrl_util_cmd + host_switch + task, shell=True
    ).decode("utf-8")
    return mstr_cntrl_util_output

def run_iserver_command_on_host_with_password(task, host, password):
    host_switch = '-m '+ host + ' '
    stop_process = pexpect.spawn (mstr_cntrl_util_cmd + host_switch + task)
    stop_process.expect (".* password:")
    stop_process.sendline (password)
    stop_process.expect(pexpect.EOF)


def get_iserver_status(host):
    status = None
    while True:
        iserver_status = run_iserver_command_on_host('gs', host)
        if 'stopped' in iserver_status:
            status = 'stopped'
            break
        if 'running' in iserver_status:
            status = 'running'
            break
        else:
            time.sleep(10)
    return status

def stop_iserver(host, password):
    iserver_status = get_iserver_status(host)
    if 'stopped' in iserver_status:
        print('host' + host + ' iServer is already in stopped state. No need to stop it')
    else:
        print('host' + host +' iServer is running. Going to stop now')
        if(socket.gethostname() == host): stop_output = run_iserver_command('stop')
        else:
            output = run_iserver_command_on_host_with_password('stop', host, password)

        iserver_status = get_iserver_status(host)
        if 'stopped' in iserver_status:
            print('host' + host +' iServer is stopped')
        else:
            print('host' + host +' Unable to stop iServer. Exiting the program')
            sys.exit(1)

def start_iserver(host, password):
    iserver_status = get_iserver_status(host)
    if 'running' in iserver_status:
        print('host' + host +' iServer is already in running state. No need to start it')
    else:
        print('host' + host +' iServer is stopped. Going to start now')
        if(socket.gethostname() == host): stop_output = run_iserver_command('start')
        else:
            output = run_iserver_command_on_host_with_password('start', host, password)

        iserver_status = get_iserver_status(host)
        if 'running' in iserver_status:
            print('host' + host +' iServer is running')
        else:
            print('host' + host +' Unable to start iServer. Exiting the program')
            sys.exit(1)


def restart_iserver(host, password):
    stop_iserver(host, password)
    start_iserver(host, password)


def restart_all_iservers(mstr_server_name, username, password):
    get_cluster_servers_script = 'LIST ALL SERVERS IN CLUSTER;'
    results_csv = get_cmd_mngr_script_result_csv(mstr_server_name, username, password, get_cluster_servers_script)
    with open(results_csv, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            restart_iserver(row['Name'], password)

def stop_all_iservers(mstr_server_name, username, password):
    get_cluster_servers_script = 'LIST ALL SERVERS IN CLUSTER;'
    results_csv = get_cmd_mngr_script_result_csv(mstr_server_name, username, password, get_cluster_servers_script)
    with open(results_csv, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            stop_iserver(row['Name'], password)


def start_all_iservers(mstr_server_name, username, password):
    get_cluster_servers_script = 'LIST ALL SERVERS IN CLUSTER;'
    results_csv = get_cmd_mngr_script_result_csv(mstr_server_name, username, password, get_cluster_servers_script)
    with open(results_csv, newline='') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            start_iserver(row['Name'], password)



def get_mstr_connection(user_name, password):
    return microstrategy.Connection(base_url = "http://localhost:8080/MicroStrategyLibrary/api", username=user_name, password=password)

def get_mstr_project_connection(user_name, password, mstr_project_name):
    return microstrategy.Connection(base_url = "http://localhost:8080/MicroStrategyLibrary/api", username=user_name, password=password, project_name = mstr_project_name)

def get_common_params(connection):
    return {
        'headers': {'X-MSTR-AuthToken': connection.auth_token,
                    'X-MSTR-ProjectID': connection.project_id},
        'cookies': connection.cookies,
        'verify': connection.ssl_verify
    }


def execute_get_api(connection, operation):
    response = requests.get(url=connection.base_url + operation, **get_common_params(connection))
    obj = json.loads(response.content)
    if not response.ok:
        raise Exception(response.content)
    return obj

def execute_post_api(connection, operation, input):
    response = requests.post(url=connection.base_url + operation, json=input, **get_common_params(connection))
    if not response.ok:
        raise Exception(response.content)


def execute_delete_api(connection, operation, input):
    response = requests.delete(url=connection.base_url + operation, params=input, **get_common_params(connection))
    if not response.ok:
        raise Exception(response.content)


def execute_command(mstr_project_source, user_name, password, command_file_name):
    command_mngr_params = "{} -n {} -u {} -p {} -showoutput -f {}".format(command_mngr_path,mstr_project_source,user_name,password,command_file_name)
    command_mngr_output = subprocess.check_output(
        command_mngr_params, shell = True
    ).decode("utf-8")
    print(command_mngr_output)

def get_command_file_result_csv(mstr_project_source, user_name, password, command_file_name):
    timestamp = '{:%Y%m%d%H%M%S}'.format(datetime.datetime.now())
    output_csv_file = '/tmp/cmd_mgr_script_' + timestamp + '_output.csv'
    command_mngr_params = "{} -n {} -u {} -p {} -showoutput -f {} -csv {}".format(command_mngr_path,mstr_project_source,user_name,password,command_file_name, output_csv_file)
    command_mngr_output = subprocess.check_output(
        command_mngr_params, shell = True
    ).decode("utf-8")
    #print(command_mngr_output)
    return output_csv_file


def import_package(mstr_project_source, user_name, password, project_name, package):
    file_name = os.path.basename(package)
    print(file_name)
    import_package_command = Template('IMPORT PACKAGE "$package_name" FOR PROJECT "$project";\n')

    undo_package_command = Template('CREATE UNDOPACKAGE "$undo_package_name" FOR PROJECT "$project" FROM PACKAGE "$package_name";\n')

    with open("/tmp/MigrationScript.scp", mode='wt') as f:
        f.write(import_package_command.substitute(package_name=package, project=project_name))

    with open("/tmp/UndoMigrationScript.scp", mode='wt') as f:
        f.write(undo_package_command.substitute(undo_package_name="/tmp/undo_"+file_name, package_name=package, project=project_name))

    execute_command(mstr_project_source, user_name, password, os.path.join(SCRIPTS_DIR, "/tmp/UndoMigrationScript.scp"))

    execute_command(mstr_project_source, user_name, password, os.path.join(SCRIPTS_DIR, "/tmp/MigrationScript.scp"))

def refresh_schema(mstr_project_source, user_name, password, project_name):
    command_template = Template('UPDATE SCHEMA REFRESHSCHEMA RECALTABLELOGICAL FOR PROJECT "$project";')
    time.sleep(10)
    execute_cmd_mngr_script(mstr_project_source, user_name, password, command_template.substitute(project = project_name))

def execute_cmd_mngr_script(mstr_project_source, user_name, password, script):
    timestamp = '{:%Y%m%d%H%M%S}'.format(datetime.datetime.now())
    cmd_mgr_file = '/tmp/cmd_mgr_script_' + timestamp + '.scp'

    with open(cmd_mgr_file, mode="wt") as f:
        f.write(script)

    execute_command(mstr_project_source, user_name, password, cmd_mgr_file)


def get_cmd_mngr_script_result_csv(mstr_project_source, user_name, password, script):
    timestamp = '{:%Y%m%d%H%M%S}'.format(datetime.datetime.now())
    cmd_mgr_file = '/tmp/cmd_mgr_script_' + timestamp + '.scp'

    with open(cmd_mgr_file, mode="wt") as f:
        f.write(script)

    return get_command_file_result_csv(mstr_project_source, user_name, password, cmd_mgr_file)



def create_user_command(mstr_project_source, login_user_name, login_user_password, new_user_name, new_user_password, new_user_full_name):

    create_user_command_template =  Template('CREATE USER "$new_user_name" PASSWORD "$new_user_password" FULLNAME "$new_user_full_name" PASSWORDEXP NEVER ENABLED;')

    create_user_command = create_user_command_template.substitute(new_user_name = new_user_name
                                                                  , new_user_password=new_user_password
                                                                  , new_user_full_name=new_user_full_name
                                                                )

    execute_cmd_mngr_script(mstr_project_source, login_user_name, login_user_password, create_user_command)

def add_user_to_group(mstr_project_source, login_user_name, login_user_password, existing_user_name, group_name):

    add_user_to_group_command_template =  Template('ADD USER "$existing_user_name" TO GROUP "$group_name";')

    add_user_to_group_command = add_user_to_group_command_template.substitute(existing_user_name = existing_user_name
                                                                              , group_name=group_name
                                                                            )

    execute_cmd_mngr_script(mstr_project_source, login_user_name, login_user_password,  add_user_to_group_command)

def user_exists(connection, user_name):
    obj = execute_get_api(connection, "/users")
    return any(user['abbreviation'] == user_name for user in obj)

def create_user(connection, user_name, password, group_id):
    user_json = {}
    user_json["username"] = user_name
    user_json["fullName"] = user_name
    user_json["password"] = password
    user_json["requireNewPassword"] = "false"
    user_json["memberships"] = group_id
    execute_post_api(connection, "/users", user_json)

def register_project(mstr_project_source, login_user_name, login_user_password, project_name):

    register_project_template =  Template('LOAD PROJECT "$project_name";REGISTER PROJECT "$project_name";')

    register_project_command = register_project_template.substitute(project_name = project_name)

    execute_cmd_mngr_script(mstr_project_source, login_user_name, login_user_password,  register_project_command)

def update_odbc_database_entry(odbc_file, odbc_entry, database_name):
    backup_file = get_file_backup(odbc_file)
    parser = SafeConfigParser(strict=False)
    parser.optionxform = str
    parser.read(odbc_file)
    parser.set(odbc_entry, 'DATABASE', database_name)
    with open(odbc_file, 'w') as configfile:
        parser.write(configfile,space_around_delimiters=False)

def get_file_backup(src):
    dst = src + '_bak_' + '{:%Y%m%d%H%M%S}'.format(datetime.datetime.now())
    copyfile(src, dst)
    return dst

def run_config_wizard(response_file):
    mstrcfgwiz_editor_path = '/opt/mstr/MicroStrategy/bin/mstrcfgwiz-editor'
    mstrcfgwiz_params = f'{mstrcfgwiz_editor_path} -r {response_file}'
    mstrcfgwiz_output = subprocess.check_output(
        mstrcfgwiz_params, shell=True
        ).decode("utf-8")
    print(mstrcfgwiz_output)

def add_projectsource(projectsource_ini, mstr_server_name):
    parser = SafeConfigParser()
    parser.optionxform = str
    parser.read(os.path.join(SCRIPTS_DIR,projectsource_ini))
    parser.set('Client', 'DataSource', mstr_server_name)
    parser.set('Client', 'ServerName', mstr_server_name)
    projectsource_file = '/tmp/' + '{:%Y%m%d%H%M%S}'.format(datetime.datetime.now()) + '_projectsource_file.ini'
    with open(projectsource_file, 'w') as inifile:
        parser.write(inifile, space_around_delimiters=False)
    run_config_wizard(projectsource_file)

def add_iserver_definition(iserver_ini, mstr_username, mstr_password):
    parser = SafeConfigParser()
    parser.optionxform = str
    parser.read(os.path.join(SCRIPTS_DIR,iserver_ini))
    parser.set('Server', 'DSNUser', mstr_username)
    parser.set('Server', 'DSNPwd', mstr_password)
    parser.set('Server', 'DSSUser', mstr_username)
    parser.set('Server', 'DSSPwd', mstr_password)
    projectsource_file = '/tmp/iserver_def_file.ini'
    with open(projectsource_file, 'w') as inifile:
        parser.write(inifile,space_around_delimiters=False)
    run_config_wizard(projectsource_file)
    #os.remove(projectsource_file)

def sync_folders(instance_id, source, destination):
    command_text = f"aws s3 sync {source} {destination}"

    return send_command(instance_id, command_text)

def send_command(instance_id, command_text):
    ssm = boto3.client("ssm")
    response = ssm.send_command(
        InstanceIds=[instance_id],
        DocumentName="AWS-RunShellScript",
        Parameters={"commands": [command_text], "executionTimeout": ["172800"]}
        # TODO: can also add cloud watch hook
    )
    return response


def get_parameter(key, decrypt=True):
        ssm = boto3.client("ssm")
        ssm_response = ssm.get_parameter(Name=key, WithDecryption=decrypt)
        return ssm_response["Parameter"]["Value"]


def put_parameter(key, value, description, type="SecureString", overwrite=False):
    ssm = boto3.client("ssm")
    ssm_response = ssm.put_parameter(
        Name=key, Value=value, Type=type, Overwrite=overwrite, Description=description
    )
    return ssm_response["Version"]


def get_instance(mstr_server_name):
    f = open("/tmp/cli_output.json", "w")
    subprocess.run(['aws','cloudformation','describe-stack-resources','--stack-name',mstr_server_name[:10],'--logical-resource-id','PlatformInstance01','--region','us-east-1'], stdout=f)

    with open('/tmp/cli_output.json', 'r') as f1:
            instance_dict = json.load(f1)

    for instance in instance_dict["StackResources"]:
            return instance['PhysicalResourceId']

def delete_existing_em_loads(mstr_project_source, login_user_name, login_user_password):

    command = 'LIST ALL DATA LOADS IN ENTERPRISE MANAGER "localhost" IN PORT 9999;'

    results_csv = get_cmd_mngr_script_result_csv(mstr_project_source, login_user_name, login_user_password, command)

    with open(results_csv, newline='') as csvfile:
        dataloads = csv.DictReader(csvfile)
        for dataload in dataloads:
            delete_em_load(mstr_project_source, login_user_name, login_user_password, dataload['Data Load name'])
            print('Deleted existing dataload - ' + dataload['Data Load name'])
            break

def delete_em_load(mstr_project_source, login_user_name, login_user_password, dataload):
    template = Template('DELETE DATA LOAD "$dataload" FROM ENTERPRISE MANAGER "localhost" IN PORT 9999;')

    command = template.substitute(dataload = dataload)

    execute_cmd_mngr_script(mstr_project_source, login_user_name, login_user_password, command)


def em_configure_project_statistics(mstr_project_source, login_user_name, login_user_password, project_name):
    template = Template('ALTER STATISTICS DBINSTANCE "Statistics" BASICSTATS ENABLED DETAILEDREPJOBS TRUE\
    DETAILEDDOCJOBS TRUE JOBSQL TRUE COLUMNSTABLES TRUE PROMPTANSWERS TRUE SUBSCRIPTIONDELIVERIES TRUE\
    INBOXMESSAGES TRUE SQLTIMEOUT 10 PURGETIMEOUT 10 IN PROJECT "$project_name";')

    command = template.substitute(project_name = project_name)

    execute_cmd_mngr_script(mstr_project_source, login_user_name, login_user_password, command)

def em_connect(mstr_project_source, login_user_name, login_user_password):
    command = 'ALTER DBINSTANCE "Statistics" DBCONNECTION "Statistics";\n ALTER DBCONNECTION "Statistics" UNIXCHARSETENCODING NONUTF8;\n ALTER DBINSTANCE "Statistics" DBCONNTYPE "MySQL 5.x";\n GRANT SECURITY ROLE "5_MicroStrategy Web Analyst Role (Client) (DIY)" TO GROUP "EM User Role - Analyst" FOR PROJECT "Enterprise Manager";'

    execute_cmd_mngr_script(mstr_project_source, login_user_name, login_user_password, command)

    command = 'CONNECT TO ENTERPRISE MANAGER "localhost" IN PORT 9999;'

    execute_cmd_mngr_script(mstr_project_source, login_user_name, login_user_password, command)

def em_start_monitoring(mstr_project_source, login_user_name, login_user_password):

    template = Template('START MONITORING SERVER "localhost" IN PORT 34952\
    USING USERNAME "$user_name" PASSWORD "$password"\
    FOR ENTERPRISE MANAGER "localhost" IN PORT 9999;')

    command = template.substitute(user_name = login_user_name, password = login_user_password)

    execute_cmd_mngr_script(mstr_project_source, login_user_name, login_user_password, command)

def em_create_data_load(mstr_project_source, login_user_name, login_user_password):

    command = 'CREATE DATA LOAD "DataLoad_Local" FOR\
    ENVIRONMENT "localhost" AND PROJECT "Enterprise Manager",\
    ENVIRONMENT "localhost" AND PROJECT "Performance Analytics"\
    DO ACTION UPDATEWAREHOUSE CLOSESESSIONS REPOPULATETABLES UPDATESTATS UPDATEOBJECTDELETIONS\
    BEGIN DATE "03/30/2017 09:00:00 +0400"\
    FREQUENCY WEEKLY ON MONDAY TUESDAY WEDNESDAY THURSDAY FRIDAY AT 06:00:00 ENABLED\
    IN ENTERPRISE MANAGER "localhost" IN PORT 9999;'

    execute_cmd_mngr_script(mstr_project_source, login_user_name, login_user_password, command)

def em_execute_data_load(mstr_project_source, login_user_name, login_user_password):

    command = 'EXECUTE DATA LOAD "DataLoad_Local" IN ENTERPRISE MANAGER "localhost" IN PORT 9999;'

    execute_cmd_mngr_script(mstr_project_source, login_user_name, login_user_password, command)

def sync_user_folders(srcFolder, dstFolder):
    for item in os.listdir(srcFolder):
        srcFile = os.path.join(srcFolder, item)
        copy2(srcFile, dstFolder)
    return True

def hide_folder(folder, parent_path, project_name, mstr_project_src, username, password):
    hide_folder_cmd = 'ALTER FOLDER "' + folder + '" IN "' + parent_path + '" HIDDEN TRUE FOR PROJECT "' + project_name + '";'
    execute_cmd_mngr_script(mstr_project_src, username, password, hide_folder_cmd)

#Get all i-Servers in the cluster
def list_all_servers_in_cluster(mstr_server_name, mstr_username, mstr_password):
    get_all_servers_in_cluster_command = "LIST ALL SERVERS IN CLUSTER;"
    results_csv = get_cmd_mngr_script_result_csv(mstr_server_name, mstr_username, mstr_password, get_all_servers_in_cluster_command)
    with open(results_csv) as csvfile:
        cluster_list_csv_obj = csv.DictReader(csvfile)
        cluster_servers = list(cluster_list_csv_obj)
    
    cluster_server_list = [each_server["Name"] for each_server in cluster_servers]
    return sorted(cluster_server_list)

def generate_password(length):
    alphabet = string.ascii_letters + string.digits
    while True:
        password = "".join(secrets.choice(alphabet) for i in range(length))
        if (
            any(char.islower() for char in password)
            and any(char.isupper() for char in password)
            and sum(char.isdigit() for char in password) >= 3
        ):
            break
    return password


def invoke_lambda(function_name, payload):
    lambda_object = boto3.client("lambda")
    lambda_response = lambda_object.invoke(
        FunctionName=function_name,
        InvocationType="RequestResponse",
        LogType="Tail",
        Payload=payload,
    )
    if lambda_response["ResponseMetadata"]["HTTPStatusCode"] == 200:
        print("Lambda Invocation Successful for the given payload")
    else:
        raise Exception(f"Lambda {function_name} Invocation Failed")


def alter_mstr_db_login(mstr_project_source, login_name, login_user_name, login_user_password, mstr_user, mstr_password):
    """ Update Password for Statistics DB Login """
    cmd_mgr_script = ALTER_DB_LOGIN_TEMPLATE.substitute(
        username = login_user_name,
        password = login_user_password,
        login_name = login_name,
    )
    execute_cmd_mngr_script(
        mstr_project_source,
        mstr_user,
        mstr_password,
        cmd_mgr_script,
    )


def execute_cmd_manager_script(mstr_info, script):
    execute_cmd_mngr_script(
        mstr_info["default_projectsource"],
        mstr_info["mstr_username"],
        mstr_info["mstr_password"],
        script,
    )


def get_cmd_mngr_script_result_csvfile_path(mstr_info, script):
    return get_cmd_mngr_script_result_csv(
        mstr_info["default_projectsource"],
        mstr_info["mstr_username"],
        mstr_info["mstr_password"],
        script,
    )


def run_command_manager(mstr_info, script):
    command_results_csv = get_cmd_mngr_script_result_csvfile_path(mstr_info, script)
    with open(command_results_csv, "r") as csvfile:
        csv_reader = csv.DictReader(csvfile)
        for row in csv_reader:
            yield row