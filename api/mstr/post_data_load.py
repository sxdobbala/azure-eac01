import os
import sys
import argparse
import csv
import mstr_utility
from string import Template
import time
import datetime
import json
import socket
import requests
from collections import deque
from time import sleep

# Retrieve all users from an User group
def get_client_usergroup_list(
    mstr_server_name, client_user_group, mstr_username, mstr_password
):
    get_client_usergroup_list_template = Template(
        'LIST LOGIN FOR USERS IN GROUP "$client_user_group";'
    )
    get_client_usergroup_list_command = get_client_usergroup_list_template.substitute(
        client_user_group=client_user_group
    )
    results_csv = mstr_utility.get_cmd_mngr_script_result_csv(
        mstr_server_name,
        mstr_username,
        mstr_password,
        get_client_usergroup_list_command,
    )
    with open(results_csv) as csvfile:
        users_csv_obj = csv.DictReader(csvfile)
        client_users = list(users_csv_obj)

    client_user_list = [each_client["Login"] for each_client in client_users]
    return client_user_list


# Retrieve Subscriptions for a list of users with a specific subscription type
def get_subscription_list_for_users(
    mstr_server_name, mstr_username, mstr_password, client_user_list, mstr_project_name
):
    subscription_command = ""
    for each_user in client_user_list:
        get_subscription_template = Template(
            'LIST SUBSCRIPTIONS FOR RECIPIENTS USER "$client_user_list" FOR PROJECT "$project_name";\n'
        )
        subscription_for_current_user = get_subscription_template.substitute(
            client_user_list=each_user, project_name=mstr_project_name
        )
        subscription_command += subscription_for_current_user

    results_csv = mstr_utility.get_cmd_mngr_script_result_csv(
        mstr_server_name, mstr_username, mstr_password, subscription_command
    )

    with open(results_csv) as csvfile:
        subscription_list_csv_obj = csv.DictReader(csvfile)
        subscription_list = list(subscription_list_csv_obj)
    subscription_guid_list = []

    for each_subscription in subscription_list:
        if each_subscription["Subscription Type"] == projectconfig["subscription_type"]:
            subscription_guid_list.append(each_subscription["GUID"])

    return subscription_guid_list


# Retrieve and Trigger the Cache Subscriptions that the users are recipients
def trigger_subscription_for_subscription_list(
    mstr_server_name,
    mstr_username,
    mstr_password,
    subscription_guid_list,
    mstr_project_name,
):
    get_trigger_guid_command = ""
    for each_subscription_guid in subscription_guid_list:
        get_guid_template = Template(
            'TRIGGER SUBSCRIPTION GUID $guid FOR PROJECT "$project_name";\n'
        )
        current_guid_command = get_guid_template.substitute(
            guid=each_subscription_guid, project_name=mstr_project_name
        )
        get_trigger_guid_command += current_guid_command

    mstr_utility.execute_cmd_mngr_script(
        mstr_server_name, mstr_username, mstr_password, get_trigger_guid_command
    )


# Purge Element Caches
def purge_element_cache(
    mstr_server_name, mstr_username, mstr_password, mstr_project_name
):
    get_purge_element_cache_template = Template(
        'PURGE ELEMENT CACHING IN PROJECT "$mstr_project_name";\n'
    )
    get_purge_element_cache_command = get_purge_element_cache_template.substitute(
        mstr_project_name=mstr_project_name
    )
    purge_cache(
        mstr_server_name, mstr_username, mstr_password, get_purge_element_cache_command
    )


# Invalidate Report Cache
def invalidate_report_cache(
    mstr_server_name, mstr_username, mstr_password, mstr_project_name
):
    """Invalidating Report cache - This doesn't include History list."""
    invalidate_report_cache_template = Template(
        'INVALIDATE ALL REPORT CACHES IN PROJECT "$mstr_project_name";\n'
    )
    invalidate_report_cache_command = invalidate_report_cache_template.substitute(
        mstr_project_name=mstr_project_name
    )
    purge_cache(
        mstr_server_name, mstr_username, mstr_password, invalidate_report_cache_command
    )


def purge_cache(mstr_server_name, mstr_username, mstr_password, command):
    list_of_cluster_servers = mstr_utility.list_all_servers_in_cluster(
        mstr_server_name, mstr_username, mstr_password
    )
    for each_server in list_of_cluster_servers:
        mstr_utility.add_projectsource(projectsource_template_ini, each_server)
        mstr_utility.execute_cmd_mngr_script(
            each_server, mstr_username, mstr_password, command
        )


# Return all cubes inside the folder
def list_folder(connection, folder_id):
    response = requests.get(
        url=f"{connection.base_url}/folders/{folder_id}",
        **mstr_utility.get_common_params(connection),
    )
    if not response.ok:
        raise Exception(json.loads(response.content))
    return json.loads(response.content)


# Publish a cube
def publish_cube(connection, cube_id):
    response = requests.post(
        url=connection.base_url + "/cubes/" + cube_id,
        **mstr_utility.get_common_params(connection),
    )
    if not response.ok:
        raise Exception(json.loads(response.content))

    content = json.loads(response.content)
    return content["instanceId"]  # Cube Instance ID


# Returns the status of a cube instance
def cube_publish_status(connection, cube_id, instance_id):
    response = requests.get(
        url=f"{connection.base_url}/datasets/{cube_id}/instances/{instance_id}/status",
        **mstr_utility.get_common_params(connection),
    )
    return response


# Kill all jobs for a user
def kill_all_jobs_for_user(
    mstr_server_name, cube_builder_username, mstr_username, mstr_password
):
    get_kill_jobs_template = Template('KILL ALL JOBS FOR "$cube_builder_username";\n')
    get_kill_jobs_command = get_kill_jobs_template.substitute(
        cube_builder_username=cube_builder_username
    )
    mstr_utility.execute_cmd_mngr_script(
        mstr_server_name, mstr_username, mstr_password, get_kill_jobs_command
    )


# Run x number of cubes at a time
def publish_multiple_cubes_and_wait(
    connection,
    cube_ids,
    parallel_execution_num,
    cube_builder_username,
    mstr_server_name,
    mstr_username,
    mstr_password,
):

    print(f"There are a total of {len(cube_ids)} cubes to be published")
    cube_instances = deque()  # Initialize a deque
    # Publishing x cubes from the list
    while len(cube_instances) < parallel_execution_num and len(cube_ids) != 0:
        each_cube = cube_ids.pop()
        cube_instances.append((each_cube, publish_cube(connection, each_cube)))

    print(f"{len(cube_instances)} cubes are concurrently being published")
    while cube_instances:

        cube_id, instance_id = cube_instances.popleft()
        status = cube_publish_status(
            connection, cube_id=cube_id, instance_id=instance_id
        )
        detail_status = json.loads(status.content)
        # print(cube_id, instance_id, status, detail_status)

        if status.ok and detail_status["status"] != 1:
            cube_instances.append(
                (cube_id, instance_id)
            )  # not failed but not finished either, so requeue
            sleep(5)

        elif (
            status.ok and detail_status["status"] == 1
        ):  # Publishing the next cube if a cube gets published
            print(f" Cube with {cube_id} has been published successfuly")
            if cube_ids:
                next_cube = cube_ids.pop()
                cube_instances.append((next_cube, publish_cube(connection, next_cube)))

        # Kill the process and cancel all cubes currently published if a cube throws error
        elif status.ok != 1:
            print(
                f"Cube refresh has failed for the cube {cube_id} and its instance {instance_id}"
            )
            print(status.content)

            if cube_instances:
                print("Killing the remaining jobs if triggered")
                list_of_cluster_servers = mstr_utility.list_all_servers_in_cluster(
                    mstr_server_name, mstr_username, mstr_password
                )
                for each_server in list_of_cluster_servers:
                    kill_all_jobs_for_user(
                        each_server, cube_builder_username, mstr_username, mstr_password
                    )
            connection.close()
            exit("Cube Refresh has failed")


## main method
if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description="Post Data Load tasks to be run in Microstrategy"
    )
    parser.add_argument(
        "--mstr_username",
        help="Username for login to the MSTR REST API",
        required="true",
    )
    parser.add_argument(
        "--mstr_password_key",
        required="true",
        help="Password key for login to the MSTR REST API",
    )
    parser.add_argument(
        "--cube_builder_username", help="Username for cube builder login"
    )
    parser.add_argument(
        "--cube_builder_password_key", help="Password key for cube builder login"
    )
    parser.add_argument(
        "--mstr_project_name", help="MicroStrategy project name", required="true"
    )
    parser.add_argument(
        "--client_id",
        help="User group name for the Client e.g. H123456 should match with MSTR User group name",
        required="true",
    )
    parser.add_argument(
        "--client_has_cubes",
        type=str,
        choices=["Y", "N"],
        help="This flag specifies if the cubes have to be published for the client",
        required="true",
    )
    parser.add_argument(
        "--dataload_type",
        type=str,
        choices=["monthly", "daily"],
        help="This flag specifies data load type for the client",
        required="true",
    )

    args = parser.parse_args()

    # Read Subscription Type and Cube List from Project Config

    with open(os.path.join(sys.path[0], "project_config.json"), "r") as f:
        projectconfig = json.load(f)

    with open(os.path.join(sys.path[0], "general_config.json"), "r") as f:
        general_config = json.load(f)

    projectsource_template_ini = general_config["projectsource_template_ini"]

    # Since Hostname will be the project source name for Clients
    mstr_server_name = socket.gethostname()
    mstr_utility.add_projectsource(projectsource_template_ini, mstr_server_name)

    # Retrieve Password from ssm Param store
    mstr_password = mstr_utility.get_parameter(args.mstr_password_key)

    # Retrieve Cube builder Password from ssm Param store
    cube_builder_password = mstr_utility.get_parameter(args.cube_builder_password_key)

    # Call Mstr Api to pass parameters and get connection object for publishing cubes - Connection is not established here
    connection = mstr_utility.get_mstr_project_connection(
        args.cube_builder_username, cube_builder_password, args.mstr_project_name
    )

    try:
        # Purge Element Caches in all servers in the cluster
        print("Purging Element Cache in all servers")
        purge_element_cache(
            mstr_server_name, args.mstr_username, mstr_password, args.mstr_project_name
        )

        # Invalidate Report Caches in all servers in the cluster (History List isn't affected by this purge)
        print("Invalidate Report Cache in all servers")
        invalidate_report_cache(
            mstr_server_name, args.mstr_username, mstr_password, args.mstr_project_name
        )

        # Publish all cubes if client uses cubes
        if args.client_has_cubes == "Y" and args.dataload_type == "monthly":
            print("Cube refresh has been initiated")
            connection.connect()
            # Retrieve Cubes from folder id in project config
            cube_list = [
                cube["id"]
                for cube in list_folder(connection, projectconfig["cube_folder_id"])
            ]

            # Publish x cubes at a time from the list
            publish_multiple_cubes_and_wait(
                connection,
                cube_list,
                projectconfig["parallel_cube_instances"],
                args.cube_builder_username,
                mstr_server_name,
                args.mstr_username,
                mstr_password,
            )

            connection.close()
            print("All cubes have been published successfully")

        # Trigger Subscriptions

        print("Trigger Subscriptions")
        client_user_list = get_client_usergroup_list(
            mstr_server_name, args.client_id, args.mstr_username, mstr_password
        )

        # Retrieve Subscriptions for the Client users
        if client_user_list:
            subscription_guid_list = get_subscription_list_for_users(
                mstr_server_name,
                args.mstr_username,
                mstr_password,
                client_user_list,
                args.mstr_project_name,
            )

        # Trigger the Subscriptions for a specific Subscription type specified in the project config file
        if subscription_guid_list:
            trigger_subscription_for_subscription_list(
                mstr_server_name,
                args.mstr_username,
                mstr_password,
                subscription_guid_list,
                args.mstr_project_name,
            )
            print("Subscriptions have been triggered successfully")
        else:
            print(
                f'There are no {projectconfig["subscription_type"]} subscriptions for this client'
            )

    except Exception as e:
        print("An error occurred while executing the script:" + str(e))
        raise e

    else:
        print("Post data load tasks for client have been executed successfully")
