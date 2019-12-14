import boto3
import logging
import json

from opa.utils import exceptions

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info(f"Event received {event}")

    cf = boto3.client("cloudformation")

    # describe_stacks throws "not found" exception for stacks in "DELETE_COMPLETE" status
    # use list_stacks instead and loop until we find the matching stack
    paginator = cf.get_paginator("list_stacks")
    page_iterator = paginator.paginate()

    complete_statuses = set(["CREATE_COMPLETE", "DELETE_COMPLETE"])
    failed_statuses = set(["CREATE_FAILED", "DELETE_FAILED"])

    for page in page_iterator:
        for stack in page["StackSummaries"]:
            if stack["StackName"] == event:
                status = stack["StackStatus"]

                if status in complete_statuses:
                    return stack["StackStatus"]

                elif status in failed_statuses:
                    raise exceptions.StackFailedError(f"Stack failed: {status}")

                else:
                    raise exceptions.StackNotReadyError(f"Stack not ready: {status}")

    raise RuntimeError(f"Stack with id {event} not found.")
