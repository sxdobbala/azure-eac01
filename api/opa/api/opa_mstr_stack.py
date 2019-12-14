import json
import boto3
import os
import argparse
import logging
import time
import time

from botocore.vendored import requests
from botocore.exceptions import ClientError
from opa.api import vars, helpers
from opa.db import postgres
from opa.utils import api, config, exceptions, http, ssm, opamaster

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    http.log_input(logger, event, context)

    try:
        operation = event["httpMethod"]

        if operation == "POST":
            return process_post_operation(event)

        elif operation == "DELETE":
            return process_delete_operation(event)

    except Exception as error:
        logger.exception(error)
        raise


def process_post_operation(event):
    mstr_config = http.get_request_parameter(event, "mstrConfig")

    # strip extraneous characters from backup url - sadly, this is how we get it as input from the previous step in the workflow
    mstr_config["mstrBakS3BucketLocation"] = helpers.clean_text(mstr_config["mstrBakS3BucketLocation"])

    response = create_mstr_environment(mstr_config)

    if not response.ok:
        raise RuntimeError(response.text)

    response_obj = response.json()
    if not response_obj["success"]:
        raise RuntimeError(response_obj["error"]["errorMessage"])

    env_id = f"env-{response_obj['data']['environmentId']}"
    enable_cf_termination_protection(env_id)
    return env_id


def process_delete_operation(event):
    env_id = http.get_request_parameter(event, "env_id")
    destroy_mstr_environment(env_id)
    return env_id


def create_mstr_environment(data):
    url = "https://developer.customer.cloud.microstrategy.com/api/environments"
    api_key = ssm.get_parameter("mstrapikey")
    headers = {"Content-Type": "application/json", "x-api-key": api_key}
    payload = json.dumps(data).encode("utf-8")
    logger.info(payload)

    response = requests.post(url=url, data=payload, headers=headers)
    logger.info(response)
    logger.info(response.text)
    return response


def destroy_mstr_environment(env_id):
    cf = boto3.client("cloudformation")
    response = cf.delete_stack(StackName=env_id)
    logger.info(response)
    return response


def enable_cf_termination_protection(env_id):
    cf = boto3.client("cloudformation")
    cf.get_waiter("stack_exists").wait(StackName=env_id, WaiterConfig={"Delay": 10, "MaxAttempts": 20})
    cf.update_termination_protection(EnableTerminationProtection=True, StackName=env_id)
