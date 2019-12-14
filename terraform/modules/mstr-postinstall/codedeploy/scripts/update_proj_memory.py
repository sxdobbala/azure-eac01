#!/usr/bin/env python3

"""Post Install Script to update MSTR memory setting of max. RAM usage for Working set, Datasets, Formatted Documents and Intelligence Cube based on EC2 instance type"""
import argparse
import json
from string import Template
from ec2_metadata import ec2_metadata
import os
import socket
import sys
mstr_infra_path = '/opt/opa/install/mstr-infra/mstr'
sys.path.append(mstr_infra_path)
import mstr_utility
import boto3
import csv
import datetime
import subprocess
import re

SET_SERVER_MAX_RAM_FOR_WORKING_SET_TEMPLATE = Template(
    "ALTER SERVER CONFIGURATION MAXRAMWORKSET $memory_size_in_KB;\n"
)
SET_PROJECT_MAX_RAM_FOR_DATASETS_TEMPLATE = Template(
    'ALTER REPORT CACHING IN PROJECT "$project_tag" MAXRAMUSAGE $memory_size_in_MB;\n'
)
SET_PROJECT_MAX_RAM_FOR_FORMATTED_DOCS_TEMPLATE = Template(
    'ALTER REPORT CACHING IN PROJECT "$project_tag" FORMATTEDDOCMAXRAMCACHE $memory_size_in_MB;\n'
)
SET_PROJECT_MAX_RAM_FOR_INTELLIGENT_CUBES_TEMPLATE = Template(
    'ALTER PROJECT CONFIGURATION INTELLIGENTCUBEMAXRAM $memory_size_in_MB IN PROJECT "$project_tag";\n'
)
LIST_SERVER_CONFIGURATION_PROPERTIES_SCRIPT = Template('LIST ALL PROPERTIES FOR SERVER CONFIGURATION;\n')
LIST_REPORT_CACHING_PROPERTIES_TEMPLATE = Template('LIST ALL PROPERTIES FOR REPORT CACHING IN PROJECT "$project_tag";\n')
LIST_PROJECT_CONFIG_PROPERTIES_TEMPLATE = Template('LIST ALL PROPERTIES FOR PROJECT CONFIGURATION IN PROJECT "$project_tag";\n')


def get_mstr_command_manager_result_file(mstr_info, script):
    timestamp = '{:%Y%m%d%H%M%S}'.format(datetime.datetime.now())
    cmd_mgr_file = '/tmp/cmd_mgr_script_' + timestamp + '.scp'
    output_file = '/tmp/cmd_mgr_script_' + timestamp + '_output.txt'

    with open(cmd_mgr_file, mode="wt") as f:
        f.write(script)
    
    with open(os.path.join(mstr_infra_path, "general_config.json"), "r") as f:
        generalconfig = json.load(f)

    command_mngr_params = "{} -n {} -u {} -p {} -showoutput -f {} -o {}".format(generalconfig['command_mngr_path'],mstr_info["default_projectsource"],mstr_info["mstr_username"],mstr_info["mstr_password"],cmd_mgr_file, output_file)
    command_mngr_output = subprocess.check_output(
        command_mngr_params, shell = True
    ).decode("utf-8")
    return output_file


def get_ssm_parameter(key, region, decrypt=True):
    ssm = boto3.client("ssm", region_name=region)
    ssm_response = ssm.get_parameter(Name=key, WithDecryption=decrypt)
    return ssm_response["Parameter"]["Value"]


def get_current_mstr_memory_limits_for_types(mstr_info, command_manager_template, mem_type):
    command_manager_script = command_manager_template.substitute(project_tag = mstr_info["project_name"])
    prop_results_csv = mstr_utility.get_cmd_mngr_script_result_csv(
        mstr_info["default_projectsource"],
        mstr_info["mstr_username"],
        mstr_info["mstr_password"],
        command_manager_script,
    )
    with open(prop_results_csv) as csvfile:
        props_data = csv.DictReader(csvfile)
        row = next(props_data)
        existing_max_RAM_value = row[mem_type]
        return int(existing_max_RAM_value)


def get_current_mstr_memory_limits_for_intelligent_cubes(mstr_info):
    list_project_config_props_script = LIST_PROJECT_CONFIG_PROPERTIES_TEMPLATE.substitute(project_tag=mstr_info["project_name"])
    prop_results_file = get_mstr_command_manager_result_file(mstr_info, list_project_config_props_script)

    with open(prop_results_file) as props_file:
        props_data = props_file.read()
    
    intelligent_cube_config = re.search(r'Intelligent Cube maximum RAM usage = ([0-9]+)', props_data)
    intelligent_cube_max_RAM_value = int(intelligent_cube_config.group(1))
    return intelligent_cube_max_RAM_value    


def set_max_RAM_usage_for_mstr_memory_type(set_max_RAM_for_mstr_memory_type_template, mstr_info, memory_size):
    set_max_RAM_for_mstr_memory_type_script = set_max_RAM_for_mstr_memory_type_template.substitute(
        project_tag=mstr_info["project_name"],
        memory_size_in_MB=memory_size,
        memory_size_in_KB=(memory_size * 1024),
    )
    mstr_utility.execute_cmd_mngr_script(
        mstr_info["default_projectsource"],
        mstr_info["mstr_username"],
        mstr_info["mstr_password"],
        set_max_RAM_for_mstr_memory_type_script,
    )

def get_existing_max_RAM_values(mstr_info):
    existing_max_RAM_values = {}
    existing_max_RAM_values["MAX_RAM_FOR_WORKING_SET"] = int(get_current_mstr_memory_limits_for_types(mstr_info, LIST_SERVER_CONFIGURATION_PROPERTIES_SCRIPT, "Maximum RAM for Working Set Cache (KBytes)") / 1024) #The value retrieved is in KB, so converted to MB to compare
    existing_max_RAM_values["MAX_RAM_FOR_DATASETS"] = get_current_mstr_memory_limits_for_types(mstr_info, LIST_REPORT_CACHING_PROPERTIES_TEMPLATE, "Max RAM Usage")
    existing_max_RAM_values["MAX_RAM_FOR_FORMATTED_DOCS"] = get_current_mstr_memory_limits_for_types(mstr_info, LIST_REPORT_CACHING_PROPERTIES_TEMPLATE, "Formatted documents maximum RAM usage")
    existing_max_RAM_values["MAX_RAM_FOR_INTELLIGENT_CUBES"] = get_current_mstr_memory_limits_for_intelligent_cubes(mstr_info)
    return existing_max_RAM_values


def get_required_max_RAM_values(mem_vs_instance_data, instance_type):
    required_max_RAM_values = {}
    required_max_RAM_values["MAX_RAM_FOR_WORKING_SET"] = mem_vs_instance_data[instance_type]["MAX_RAM_FOR_WORKING_SET"]
    required_max_RAM_values["MAX_RAM_FOR_DATASETS"] = mem_vs_instance_data[instance_type]["MAX_RAM_FOR_DATASETS"]
    required_max_RAM_values["MAX_RAM_FOR_FORMATTED_DOCS"] = mem_vs_instance_data[instance_type]["MAX_RAM_FOR_FORMATTED_DOCS"]
    required_max_RAM_values["MAX_RAM_FOR_INTELLIGENT_CUBES"] = mem_vs_instance_data[instance_type]["MAX_RAM_FOR_INTELLIGENT_CUBES"]
    return required_max_RAM_values

def set_max_RAM_usage_for_mstr_based_on_instance_type(mstr_info):
    instance_type = ec2_metadata.instance_type

    mstr_memory_config_file = os.path.join(
        os.path.abspath(os.path.dirname(__file__)), "mstr_mem_type_vs_instance_config.json"
    )
    with open(mstr_memory_config_file, "r") as mstr_mem_config_file:
        mem_vs_instance_data = json.load(mstr_mem_config_file)
    
    if instance_type not in mem_vs_instance_data:
        raise KeyError(f'MSTR memory limits not set in the config file({mstr_memory_config_file}) for instance type - "{instance_type}"')

    mem_values_changed_flag = False

    existing_max_RAM_values = get_existing_max_RAM_values(mstr_info)
    required_max_RAM_values = get_required_max_RAM_values(mem_vs_instance_data, instance_type)

    if existing_max_RAM_values["MAX_RAM_FOR_WORKING_SET"] != required_max_RAM_values["MAX_RAM_FOR_WORKING_SET"]:
        set_max_RAM_usage_for_mstr_memory_type(
            SET_SERVER_MAX_RAM_FOR_WORKING_SET_TEMPLATE,
            mstr_info,
            required_max_RAM_values["MAX_RAM_FOR_WORKING_SET"],
        )
        print(f"Max. RAM for working set changed from {existing_max_RAM_values['MAX_RAM_FOR_WORKING_SET']}MB to {required_max_RAM_values['MAX_RAM_FOR_WORKING_SET']}MB")
        mem_values_changed_flag = True

    if existing_max_RAM_values["MAX_RAM_FOR_DATASETS"] != required_max_RAM_values["MAX_RAM_FOR_DATASETS"]:
        set_max_RAM_usage_for_mstr_memory_type(
            SET_PROJECT_MAX_RAM_FOR_DATASETS_TEMPLATE,
            mstr_info,
            mem_vs_instance_data[instance_type]["MAX_RAM_FOR_DATASETS"],
        )
        print(f"Max. RAM for datasets changed from {existing_max_RAM_values['MAX_RAM_FOR_DATASETS']}MB to {required_max_RAM_values['MAX_RAM_FOR_DATASETS']}MB")
        mem_values_changed_flag = True

    if existing_max_RAM_values["MAX_RAM_FOR_FORMATTED_DOCS"] != required_max_RAM_values["MAX_RAM_FOR_FORMATTED_DOCS"]:
        set_max_RAM_usage_for_mstr_memory_type(
            SET_PROJECT_MAX_RAM_FOR_FORMATTED_DOCS_TEMPLATE,
            mstr_info,
            mem_vs_instance_data[instance_type]["MAX_RAM_FOR_FORMATTED_DOCS"],
        )
        print(f"Max. RAM for formatted documents changed from {existing_max_RAM_values['MAX_RAM_FOR_FORMATTED_DOCS']}MB to {required_max_RAM_values['MAX_RAM_FOR_FORMATTED_DOCS']}MB")
        mem_values_changed_flag = True
    
    if existing_max_RAM_values["MAX_RAM_FOR_INTELLIGENT_CUBES"] != required_max_RAM_values["MAX_RAM_FOR_INTELLIGENT_CUBES"]:
        set_max_RAM_usage_for_mstr_memory_type(
            SET_PROJECT_MAX_RAM_FOR_INTELLIGENT_CUBES_TEMPLATE,
            mstr_info,
            mem_vs_instance_data[instance_type]["MAX_RAM_FOR_INTELLIGENT_CUBES"],
        )
        print(f"Max. RAM for intelligent cubes changed from {existing_max_RAM_values['MAX_RAM_FOR_INTELLIGENT_CUBES']}MB to {required_max_RAM_values['MAX_RAM_FOR_INTELLIGENT_CUBES']}MB")
        mem_values_changed_flag = True
    
    return mem_values_changed_flag


def restart_iservers(mstr_info):
    mstr_utility.restart_all_iservers(mstr_info["default_projectsource"], mstr_info["mstr_username"], mstr_info["mstr_password"])
    print("Restarted all the iServers.")


if __name__ == "__main__":
    default_project_source = "mstr_metadata"

    parser = argparse.ArgumentParser(
        description="Configures MSTR memory setting of max. RAM usage for Working set, Datasets, Formatted Documents and Intelligence Cube based on EC2 instance typen"
    )
    parser.add_argument(
        "--mstr_project",
        help="Microstrategy project for which memory settings need to be configured",
        required="true",
    )
    parser.add_argument(
        "--mstr_username", help="MicroStrategy UserName", required="true"
    )
    parser.add_argument(
        "--mstr_password_key", help="Microstrategy Password", required="true"
    )
    args = parser.parse_args()

    mstr_info = {}
    mstr_info["default_projectsource"] = default_project_source
    mstr_info["project_name"] = args.mstr_project
    mstr_info["mstr_username"] = args.mstr_username
    mstr_info["mstr_password"] = get_ssm_parameter(args.mstr_password_key, ec2_metadata.region)

    if set_max_RAM_usage_for_mstr_based_on_instance_type(mstr_info):
        restart_iservers(mstr_info)
    else:
        print("No max RAM usage settings were changed for any MSTR memory type.")