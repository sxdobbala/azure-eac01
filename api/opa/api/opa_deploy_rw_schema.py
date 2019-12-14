"""
  This lambda is used to deploy ReadWrite (RW) schema
  and sends message with Success or Failed status to opa-release SNS topic.
  It expects that sync release package from S3 to target instance already ran
  and schema.read_write.jar exists in /opt/opa/local/current_release/ on target instance.
"""

import json
import boto3
import os
import logging

from opa.api import vars, helpers
from opa.utils import api, config, opamaster, exceptions

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# TODO: ensure SFN is signaled in case of exception


def lambda_handler(event, context):
    logger.info(f"Received event: {event}")

    # get input params
    env_id = helpers.clean_text(event["envId"])

    # grab connection to opa master
    conn = helpers.get_opa_master_connection()

    # when a single client id is passed we're deploying RW for a branch client which is not in OPA Master yet;
    # therefore redshift id is also required as a parameter
    if "clientId" in event:
        existing_client = False
        client_ids = [event["clientId"]]
        redshift_id = event["redshiftId"]

    # otherwise figure out which clients are on the given environment/stack;
    # we'll retrieve their redshift id's from OPA Master later
    else:
        existing_client = True
        client_ids = opamaster.lookup_client_ids(config.ENV_ID, env_id, conn)

    logger.info(f"client_ids={client_ids}")

    # throw exception if no clients are found on that environment
    # no commands can be run so let the caller handle the exception
    if not client_ids:
        raise exceptions.ClientNotFoundError(f"No client(s) found on {env_id}")

    commands = []

    # for each of the clients construct a command to be run and collate the commands
    for client_id in client_ids:
        logger.info(f"client_id={client_id}")

        if existing_client:
            client_configs = opamaster.load_config(client_id, None, conn)
            # for backward compatibility with existing clients check both REDSHIFT_ID and REDSHIFT_ID_OLD in that order
            redshift_id = client_configs.get(
                config.REDSHIFT_ID, client_configs.get(config.REDSHIFT_ID_OLD, None)
            )
            if not redshift_id:
                logger.warn(f"clientId={client_id} is missing a Redshift configuration")
                continue

        command = get_command_text(client_id, redshift_id)
        logger.info(f"command={command}")
        commands.append(command)

    # run the command on the primary node of the environment
    ssm = boto3.client("ssm")
    platform_instance_id = helpers.get_stack_output_value(env_id, "PlatformInstance01")
    cloudwatch_log_group = f"/opa/{vars.ENV_PREFIX}/opa_deploy_rw_schema"
    # TODO: refactor this to use utility SSM send_command code
    result = ssm.send_command(
        InstanceIds=[platform_instance_id],
        DocumentName="AWS-RunShellScript",
        Parameters={"commands": commands},
        ServiceRoleArn=vars.OPA_RELEASE_SNS_ROLE_ARN,
        NotificationConfig={
            "NotificationArn": vars.OPA_RELEASE_SNS_TOPIC_ARN,
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


def get_command_text(client_id, redshift_id):
    redshift_details = helpers.get_redshift_details(redshift_id)
    redshift_host = redshift_details["host"]
    redshift_port = redshift_details["port"]
    redshift_username = redshift_details["username"]
    redshift_client_database = helpers.get_redshift_client_database(client_id)
    redshift_client_username = helpers.get_redshift_client_username(client_id)

    redshift_jdbc_url = (
        f"jdbc:redshift://{redshift_host}:{redshift_port}/{redshift_client_database}"
    )

    cmd_line_args = f"-Durl={redshift_jdbc_url} -Duser={redshift_username} -Dregion={vars.AWS_REGION} -Dmstr_db_user={redshift_client_username}"
    command = f"""/opt/jdk/java/bin/java {cmd_line_args} -jar /opt/opa/local/current_release/schema.read_write.jar"""
    return command

