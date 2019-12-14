import json
import logging
import sys
import boto3
import os

from opa.api import vars, helpers
from opa.utils import config, exceptions, http, opamaster, api, ssm

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
                instance_id, config.DATA_LOAD_COMMAND_ID, client_configs, True, True
            )

            return http.success(response)

        elif operation == "POST":
            client_id = http.get_request_parameter(event, "clientId")
            client_configs = opamaster.load_config(client_id, None, conn)
            instance_id = helpers.get_instance_id(client_configs[config.ENV_ID])
            s3_prefix = http.get_request_parameter(event, "s3_prefix", required=True)
            dataload_type = http.get_request_parameter(
                event, "dataload_type", required=True
            )
            response = api.get_operation_status(
                instance_id, config.DATA_LOAD_COMMAND_ID, client_configs, False
            )

            # we cannot begin a data load if there is another one running already
            if response is not None:
                if api.is_script_running(response):
                    return http.bad_request(
                        f"Cannot start data load for client {client_id} while another one is running."
                    )

            # run the script and save its command id to OPA master
            command_response = run_script(
                event, client_id, client_configs, s3_prefix, dataload_type
            )
            config_data = {
                config.DATA_LOAD_COMMAND_ID: command_response["Command"]["CommandId"]
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


def run_script_args(event, client_id, configs, s3_prefix, dataload_type):
    config_keys = configs.keys()
    task_token = event.get("token", None)

    # first check to see if script name and runtime are provided in the lambda inputs
    if "scriptName" in event["body"] and "scriptRuntime" in event["body"]:
        script_runtime = event["body"]["scriptRuntime"]
        script_name = event["body"]["scriptName"]
        # assume OPADDL folder is a sibling of the script
        ddl_base_path = f"{os.path.dirname(script_name)}/OPADDL"

    # otherwise check OPA Master for script settings
    elif (
        config.DATA_LOAD_SCRIPT_NAME in config_keys
        and config.DATA_LOAD_DDL_BASE_PATH in config_keys
    ):
        script_runtime = vars.SCRIPT_RUNTIME
        script_name = configs[config.DATA_LOAD_SCRIPT_NAME]
        ddl_base_path = configs[config.DATA_LOAD_DDL_BASE_PATH]

    # otherwise grab script settings from environment variables
    else:
        script_runtime = vars.SCRIPT_RUNTIME
        script_name = os.path.join(vars.SCRIPT_PATH_DATA_LOAD, "dataload_invoker.sh")
        ddl_base_path = os.path.join(vars.SCRIPT_PATH_DATA_LOAD, "OPADDL")

    logger.info(f"script_runtime = {script_runtime}")
    logger.info(f"script_name = {script_name}")
    logger.info(f"ddl_base_path = {ddl_base_path}")

    # for backward compatibility with existing clients check both REDSHIFT_ID and REDSHIFT_ID_OLD in that order
    redshift_id = configs.get(
        config.REDSHIFT_ID, configs.get(config.REDSHIFT_ID_OLD, None)
    )
    redshift_details = helpers.get_redshift_details(redshift_id)
    redshift_client_database = helpers.get_redshift_client_database(client_id)

    instance_id = helpers.get_instance_id(configs[config.ENV_ID])

    script_args = []
    script_args.append(f"--host_name {redshift_details['host']}")
    script_args.append(f"--db_name {redshift_client_database}")
    script_args.append(f"--port {redshift_details['port']}")
    script_args.append(f"--user_name {redshift_details['username']}")
    script_args.append(f"--bucket {configs[config.DATA_LOAD_DATA_BUCKET]}")
    script_args.append(f"--file_prefix {s3_prefix}")
    script_args.append(f"--iam_role {configs[config.DATA_LOAD_IAM_ROLE]}")
    script_args.append(f"--ddl_base_path {configs[config.DATA_LOAD_DDL_BASE_PATH]}")
    script_args.append(f"--dataload_type {dataload_type}")

    cloudwatch_log_group = f"/opa/{vars.ENV_PREFIX}/opa_data_load"
    return (
        instance_id,
        script_runtime, 
        script_name, 
        script_args, 
        cloudwatch_log_group,
        None,
        None,
        task_token,
    )


def run_script(event, client_id, configs, s3_prefix, dataload_type):
    args = run_script_args(event, client_id, configs, s3_prefix, dataload_type)

    response = ssm.run_script(*args)

    return response
