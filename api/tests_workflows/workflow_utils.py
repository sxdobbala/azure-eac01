import pytest  # pylint: disable=import-error
import json
import logging
import boto3
import time
import string
import random
import os

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def generate_random_string(length, min_lower=1, min_upper=1, min_digits=1):
    alphabet = string.ascii_letters + string.digits
    while True:
        value = "".join(random.SystemRandom().choice(alphabet) for i in range(length))
        if (
            sum(c.islower() for c in value) >= min_lower
            and sum(c.isupper() for c in value) >= min_upper
            and sum(c.isdigit() for c in value) >= min_digits
        ):
            return value


def assert_execution(sfn_arn, execution_arn):
    client = boto3.client("stepfunctions")

    while True:
        paginator = client.get_paginator("list_executions")
        page_iterator = paginator.paginate(stateMachineArn=sfn_arn)

        for page in page_iterator:
            for execution in page["executions"]:
                if execution["executionArn"] == execution_arn:
                    logger.info(execution)
                    break

        assert execution, f"Execution {execution_arn} not found."

        status = execution["status"]

        if not status == "RUNNING":
            assert status == "SUCCEEDED", f"Execution {execution_arn} did not succeed."
            break

        time.sleep(60)


def assert_workflow(sfn_arn, sfn_name, sfn_payload):
    client = boto3.client("stepfunctions")

    response = client.start_execution(
        stateMachineArn=sfn_arn, name=sfn_name, input=sfn_payload
    )
    print(response)

    assert_execution(sfn_arn, response["executionArn"])

