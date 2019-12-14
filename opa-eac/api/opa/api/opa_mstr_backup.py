import json
import logging
import boto3
import sys
import datetime
import botocore
import os

from botocore.client import Config
from opa.api import vars, helpers
from opa.utils import http, api, config, exceptions, opamaster, constants, ssm


logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info(f"Event received: {event}")

    conn = helpers.get_opa_master_connection()

    client_id = event["clientId"]
    client_configs = opamaster.load_config(client_id, None, conn)
    s3_bucket_name = vars.MSTR_BACKUPS_BUCKET
    s3_key_name = get_s3_key_name(client_id, client_configs)

    run_script(event, client_configs, s3_bucket_name, s3_key_name)

    # The output of the lambda will be ignored because the step function will wait 
    # for the task token, and it will use the payload from the token that's sent from ssm command itself.
    # Keeping the response here because the output is useful when running the lambda outside of sfn
    s3_object_url = get_s3_object_url(s3_bucket_name, s3_key_name)

    return s3_object_url


def get_s3_key_name(client_id, configs):
    env_id = configs[config.ENV_ID]
    timestamp = datetime.datetime.now().isoformat()

    # TODO: MSTR recently broke backups and requires backup to be at root level of S3 bucket - update backup key when they fix it
    # s3_key_name = f"mstr_backups/{vars.ENV_PREFIX}/backup.{client_id}.{env_id}.{timestamp}.tar.gz"
    s3_key_name = f"{vars.ENV_PREFIX}.backup.{client_id}.{env_id}.{timestamp}.tar.gz"
    s3_key_name = s3_key_name.replace("-", "_").replace(":", "_")

    return s3_key_name


def get_s3_object_url(bucket, key):
    return f"https://{bucket}.s3.amazonaws.com/{key.strip('/')}"


def run_script_args(event, configs, s3_bucket_name, s3_key_name):
    script_runtime = event.get("scriptRuntime", vars.SCRIPT_RUNTIME)
    script_name = event.get("scriptName", os.path.join(vars.SCRIPT_PATH_MSTR, "mstr_backup_invoker.sh"))
    task_token = event.get("token", None)
    instance_id = helpers.get_instance_id(configs[config.ENV_ID])
    env_id = configs[config.ENV_ID]
    mstr_password_key = helpers.get_mstr_password_key(env_id)

    script_args = [
        f"--mstr-username {constants.MSTR_USERNAME}",
        f"--mstr-password-key {mstr_password_key}",
        f"--mysql-username {constants.MSTR_MYSQL_USERNAME}",
        f"--mysql-password-key {helpers.get_mstr_password_key(env_id)}",
        f"--s3-bucket-name {s3_bucket_name}",
        f"--s3-key-name {s3_key_name}",
    ]
    if "dumpMode" not in event or event["dumpMode"]:  # default to dump mode unless explicitly provided with false or empty string
        script_args.append("--dump-mode")

    cloudwatch_log_group = f"/opa/{vars.ENV_PREFIX}/opa_mstr_backup"
    
    s3_object_url = get_s3_object_url(s3_bucket_name, s3_key_name)
    logger.info(s3_object_url)
    task_payload = {"Payload": s3_object_url}

    return (
        instance_id,
        script_runtime,
        script_name,
        script_args,
        cloudwatch_log_group,
        None,
        None,
        task_token,
        task_payload,
    )


def run_script(event, configs, s3_bucket_name, s3_key_name):
    args = run_script_args(event, configs, s3_bucket_name, s3_key_name)
    response = ssm.run_script(*args)
    return response
