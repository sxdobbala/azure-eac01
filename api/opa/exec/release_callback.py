"""
   This lambda will be triggered by opa-release SNS topic once it receives a message.
   This lambda will handle the SNS message and send_task_success or failure to opa-release step function.
"""

import json
import os
import boto3
import logging

from opa.utils import api
from opa.api import vars

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info(f"Event received: {event}")

    params = event_dict(event)
    sf = boto3.client("stepfunctions")
    ssm = boto3.client("ssm")

    status = params["status"]

    # commandId param comes from step 1 sync release or step 3 deploy MSTR
    if "commandId" in params:
        param_name = f"/{vars.ENV_PREFIX}/{params['commandId']}"
    # deploymentId param comes from step 2 deploy opa
    elif "deploymentId" in params:
        param_name = f"/{vars.ENV_PREFIX}/{params['deploymentId']}"

        # get "Failed" number from deploymentOverview
        deployment_overview = json.loads(params["deploymentOverview"])
        deployment_overview_failed_num = int(deployment_overview["Failed"])
        if deployment_overview_failed_num > 0:
            status = "failed"
    else:
        raise Exception("No valid parameter provided")

    response = ssm.get_parameter(Name=param_name)
    token = response["Parameter"]["Value"]
    ssm.delete_parameter(Name=param_name)

    if status.lower() in ["success", "succeeded"]:
        sf.send_task_success(taskToken=token, output=json.dumps({"status": "success"}))
        return "success"
    if status.lower() in ["failed"]:
        sf.send_task_failure(taskToken=token, error="Task Failed")
        return "Failed"


def event_dict(event):
    logger.info(event)
    message = event["Records"][0]["Sns"]["Message"].strip()
    return json.loads(message)

