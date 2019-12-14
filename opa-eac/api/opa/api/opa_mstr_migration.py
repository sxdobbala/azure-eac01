import json
import logging
import sys
import boto3
import os

from opa.api import vars, helpers
from opa.utils import ssm, constants

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info(f"Event received: {event}")

    env_id = helpers.clean_text(event["envId"])

    command_response = run_script(event, env_id)
    command_id = command_response["Command"]["CommandId"]

    # save token if present
    helpers.save_token(command_id, event)

    return command_id


def run_script_args(event, env_id):
    script_runtime = event.get("scriptRuntime", vars.SCRIPT_RUNTIME)
    script_name = event.get(
        "scriptName",
        os.path.join(vars.SCRIPT_PATH_MSTR, "migrate_mstr_objects_invoker.sh"),
    )
    task_token = event.get("token", None)
    instance_id = helpers.get_instance_id(env_id)
    # TODO: this might be better as an env var or at least for the base path "/opt/opa/install/"
    migration_filename = f"{constants.MIGRATION_BASE_FOLDER}/migration_file.yaml"
    mstr_password_key = helpers.get_mstr_password_key(env_id)

    script_args = []
    script_args.append(f"--mstr_project_name '{constants.MSTR_PROJECT_NAME}'")
    script_args.append(f"--mstr_username {constants.MSTR_USERNAME}")
    script_args.append(f"--mstr_password_key {mstr_password_key}")
    script_args.append(f"--migration_base_folder {constants.MIGRATION_BASE_FOLDER}")
    script_args.append(f"--migration_file {migration_filename}")
    script_args.append(f"--migration_strategy delta")

    cloudwatch_log_group = f"/opa/{vars.ENV_PREFIX}/opa_mstr_migration"

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


def run_script(event, env_id):
    args = run_script_args(event, env_id)
    response = ssm.run_script(*args)
    return response

