import os
import json
import collections
import logging
import boto3

from opa.utils import exceptions, ssm

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def get_operation_status(
    instance_id, command_key, configs, command_id_required=True, include_logs=False
):
    if command_key not in configs:
        # command id is required when running get_operation_status on a GET operation
        # this is when we expect to be able to retrieve the status of a prior async operation
        if command_id_required:
            raise exceptions.ApiConfigSettingNotFound(
                f"Operation has never been run for this client."
            )
        else:
            return None

    command_id = configs[command_key]

    try:
        return ssm.get_command_status(instance_id, command_id, include_logs)
    except:
        if command_id_required:
            raise
        else:
            return None


def is_script_running(response):
    if response["ResponseMetadata"]["HTTPStatusCode"] != "200":
        return False

    return response["Status"] in {"Pending", "InProgress", "Delayed", "Cancelling"}


def get_os_environ_value(key, default_value=""):
    try:
        return os.environ[key]
    except:
        return default_value
