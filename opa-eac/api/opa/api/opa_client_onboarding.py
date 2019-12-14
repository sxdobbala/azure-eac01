import json
import logging
import sys
import boto3
import os

from opa.api import vars, helpers
from opa.utils import api, config, exceptions, http, ssm, opamaster, constants, tagging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info(f"Event received: {event}")

    client_id = event["clientId"]

    conn = helpers.get_opa_master_connection()

    try:
        # for stack rotation - get the client settings from OPA Master
        client_configs = opamaster.load_config(client_id, None, conn)
        client_name = client_configs[config.CLIENT_NAME]
        client_has_egr = client_configs[config.CLIENT_HAS_EGR]

    except (exceptions.ApiConfigSettingNotFound, KeyError) as error:
        # for new client onboardings - get the client settings from lambda inputs
        logger.exception(error)
        client_name = event["clientName"]
        client_has_egr = event["clientHasEGR"]

    env_id = helpers.clean_text(event["envId"])
    instance_id = helpers.get_instance_id(env_id)
    redshift_id = event["redshiftId"]

    logger.info("Running client provisioning script")
    command_response = run_script(
        event, client_id, client_name, client_has_egr, env_id, instance_id, redshift_id
    )
    command_id = command_response["Command"]["CommandId"]

    # save token if present
    helpers.save_token(command_id, event)

    logger.info("apply client tag")
    apply_client_tag(env_id, redshift_id, client_id, client_name)

    return command_id


def run_script_args(
    event, client_id, client_name, client_has_egr, env_id, instance_id, redshift_id
):
    script_runtime = event.get("scriptRuntime", vars.SCRIPT_RUNTIME)
    script_name = event.get(
        "scriptName",
        os.path.join(vars.SCRIPT_PATH_MSTR, "create_new_client_invoker.sh"),
    )
    task_token = event.get("token", None)
    mstr_password_key = helpers.get_mstr_password_key(env_id)
    redshift_details = helpers.get_redshift_details(redshift_id)
    redshift_client_database = helpers.get_redshift_client_database(client_id)
    redshift_client_username = helpers.get_redshift_client_username(client_id)

    script_args = []
    script_args.append(f"--client_id {client_id}")
    script_args.append(f"--client_name '{client_name}'")
    script_args.append(f"--client_has_egr {client_has_egr}")
    # TODO: client_reporting_db does not make sense as a param name - it should be redshift_database
    # will need to update this also in https://github.optum.com/opa/mstr-infra/blob/master/scripts/create_new_client.py
    script_args.append(f"--mstr_project_name '{constants.MSTR_PROJECT_NAME}'")
    script_args.append(f"--mstr_username {constants.MSTR_USERNAME}")
    script_args.append(f"--mstr_password_key {mstr_password_key}")
    script_args.append(f"--redshift_id {redshift_id}")
    script_args.append(f"--redshift_host {redshift_details['host']}")
    script_args.append(f"--redshift_port {redshift_details['port']}")
    script_args.append(f"--redshift_username {redshift_details['username']}")
    script_args.append(f"--client_reporting_db {redshift_details['database']}")
    script_args.append(f"--redshift_client_database {redshift_client_database}")
    script_args.append(f"--redshift_client_username {redshift_client_username}")
    # TODO: should we allow this or any other script to save to OPA Master?
    script_args.append(f"--opa_master_lambda {vars.OPA_MASTER_LAMBDA}")

    logger.info(script_args)

    cloudwatch_log_group = f"/opa/{vars.ENV_PREFIX}/opa_client_onboarding"
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


def run_script(
    event, client_id, client_name, client_has_egr, env_id, instance_id, redshift_id
):
    args = run_script_args(
        event, client_id, client_name, client_has_egr, env_id, instance_id, redshift_id
    )
    response = ssm.run_script(*args)
    return response

def apply_client_tag(env_id, redshift_id, client_id, client_name):
    tags = dict()
    
    #dict of tags to add
    tags[f"optum:client:{client_id}:{client_name}"] = ""
    
    #apply tags
    tagging.apply_tags_to_ec2(env_id, tags)
    tagging.apply_tags_to_redshift(redshift_id, tags)