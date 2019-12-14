"""
  This lambda is usesd to sync release package in S3 to target instance
  and send message with Success or Failed status to opa-release SNS topic.
"""

import json
import boto3
import os
import logging

from opa.utils import api
from opa.api import helpers, vars

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info(f"Event received: {event}")

    env_id = helpers.clean_text(event["envId"])
    release_id = event["releaseId"]

    sns_topic_arn = api.get_os_environ_value("SNS_TOPIC_ARN")
    sns_role_arn = api.get_os_environ_value("SNS_ROLE_ARN")
    artifacts_s3_bucket = api.get_os_environ_value("ARTIFACTS_S3_BUCKET")
    opa_release_s3_bucket = api.get_os_environ_value("OPA_RELEASE_S3_BUCKET")
    opa_release_s3_prefix = api.get_os_environ_value("OPA_RELEASE_S3_PREFIX")
    opa_release_bucket_id = f"s3://{opa_release_s3_bucket}/{opa_release_s3_prefix}"
    opa_api_mstr_bucket_id = f"s3://{artifacts_s3_bucket}/{vars.ENV_PREFIX}/opa.api"

    commands = [
        f"""aws s3 cp s3://{artifacts_s3_bucket}/{vars.ENV_PREFIX}/opa-release/sync.sh /opt/opa/local/ && \
        sudo chmod +x /opt/opa/local/sync.sh && \
        sh /opt/opa/local/sync.sh {opa_release_bucket_id} {release_id} {opa_api_mstr_bucket_id} \
        """
    ]

    ssm = boto3.client("ssm")
    platform_instance_id = helpers.get_stack_output_value(env_id, "PlatformInstance01")
    cloudwatch_log_group = f"/opa/{vars.ENV_PREFIX}/sync-release"
    result = ssm.send_command(
        InstanceIds=[platform_instance_id],
        DocumentName="AWS-RunShellScript",
        Parameters={"commands": commands},
        ServiceRoleArn=sns_role_arn,
        NotificationConfig={
            "NotificationArn": sns_topic_arn,
            "NotificationEvents": ["Success", "Failed"],
        },
        CloudWatchOutputConfig={
            "CloudWatchLogGroupName": cloudwatch_log_group,
            "CloudWatchOutputEnabled": True,
        },
    )
    logger.info(result)

    # save token if present
    command_id = result["Command"]["CommandId"]
    helpers.save_token(command_id, event)

    return command_id

