import json
import logging
import sys
import boto3
import os

from opa.api import vars, helpers
from opa.utils import api, ssm, config, exceptions, http, opamaster, constants

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    http.log_input(logger, event, context)

    try:
        operation = event["httpMethod"]

        conn = helpers.get_opa_master_connection()

        if operation == "GET":
            client_id = http.get_request_parameter(event, "clientId")
            client_configs = opamaster.load_config(client_id, None, conn)
            instance_id = helpers.get_instance_id(client_configs[config.ENV_ID])
            response = api.get_operation_status(
                instance_id, config.POST_DATA_LOAD_COMMAND_ID, client_configs
            )

            return http.success(response)

        elif operation == "POST":
            client_id = http.get_request_parameter(event, "clientId")
            client_configs = opamaster.load_config(client_id, None, conn)
            instance_id = helpers.get_instance_id(client_configs[config.ENV_ID])
            dataload_type = http.get_request_parameter(
                event, "dataload_type", required=True
            )
            response = api.get_operation_status(
                instance_id, config.POST_DATA_LOAD_COMMAND_ID, client_configs, False
            )

            # we cannot begin a the execution of post data load scripts if there is another one running already for a different client.
            if response is not None:
                if api.is_script_running(response):
                    return http.bad_request(
                        f"Cannot execute post data load scripts for client {client_id} while another one is running."
                    )

            # run the script and save its command id to OPA master
            command_response = run_script(
                event, client_id, client_configs, dataload_type
            )
            config_data = {
                config.POST_DATA_LOAD_COMMAND_ID: command_response["Command"][
                    "CommandId"
                ]
            }
            opamaster.save_config(client_id, config_data, conn)

            return http.success(command_response)

        else:
            return http.method_not_allowed({"GET", "POST"})

    except exceptions.ApiMissingRequestParameter as error:
        logger.exception(error)
        return http.bad_request(error.message)

    except exceptions.ApiConfigSettingNotFound as error:
        logger.exception(error)
        return http.not_found(error.message)

    except Exception as error:
        logger.exception(error)
        return http.internal_server_error()


def run_script_args(event, client_id, configs, dataload_type):
    script_runtime = event.get("scriptRuntime", vars.SCRIPT_RUNTIME)
    script_name = event["body"].get(
        "scriptName", os.path.join(vars.SCRIPT_PATH_MSTR, "post_data_load_invoker.sh")
    )
    task_token = event.get("token", None)
    instance_id = helpers.get_instance_id(configs[config.ENV_ID])
    env_id = configs[config.ENV_ID]
    mstr_password_key = helpers.get_mstr_password_key(env_id)
    cube_builder_username = helpers.get_cube_builder_username(client_id)
    cube_builder_password_key = helpers.get_cube_builder_password_key(client_id, env_id)

    script_args = []
    script_args.append(f"--client_id {client_id}")
    script_args.append(f"--mstr_project_name '{constants.MSTR_PROJECT_NAME}'")
    script_args.append(f"--mstr_username {constants.MSTR_USERNAME}")
    script_args.append(f"--mstr_password_key {mstr_password_key}")
    script_args.append(f"--client_has_cubes {configs[config.CLIENT_HAS_CUBES]}")
    script_args.append(f"--cube_builder_username '{cube_builder_username}'")
    script_args.append(f"--cube_builder_password_key {cube_builder_password_key}")

    script_args.append(f"--dataload_type {dataload_type}")

    cloudwatch_log_group = f"/opa/{vars.ENV_PREFIX}/opa_post_data_load"

    return (
        instance_id,
        script_runtime,
        script_name,
        script_args,
        cloudwatch_log_group,
        None,
        None,
        task_token
    )


def run_script(event, client_id, configs, dataload_type):
    args = run_script_args(event, client_id, configs, dataload_type)
    response = ssm.run_script(*args)
    return response
