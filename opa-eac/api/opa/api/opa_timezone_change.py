import json
import logging
import os
import re
import sys
import time
import boto3

from opa.utils import api, ssm
from opa.api import helpers, vars

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info(f"Received event: {event}")

    # get input params
    env_id = helpers.clean_text(event["envId"])

    # Make sure the timezone on EC2 instances is Eastern Time
    change_timezone(env_id)

    return "Success"


def change_timezone(env_id):
    ec2_client = boto3.client("ec2")

    instance_ids = helpers.get_instance_ids(env_id)

    for i in instance_ids:
        check_timezone = ssm.send_command(
            instance_id=i,
            command_text="date +%Z",
            cloudwatch_log_group=f"/opa/{vars.ENV_PREFIX}/timezone_script",
        )

        server_timezone = ssm.poll_command_output(
            i, check_timezone["Command"]["CommandId"]
        )

        logger.info(f"Timezone on instance {i} is {server_timezone}")
        if not server_timezone in ["EST", "EDT"]:
            logger.info("Timezone is not America/New_York, changing...")

            change_timezone = ssm.send_command(
                instance_id=i,
                command_text='echo -e ZONE="America/New_York" \nUTC=true > /etc/sysconfig/clock; ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime',
                cloudwatch_log_group=f"/opa/{vars.ENV_PREFIX}/timezone_script",
            )

            is_success = ssm.poll_command_status(
                i, change_timezone["Command"]["CommandId"]
            )

            if is_success:
                logger.info("SSM command for timezone change succeeded")
                # Reboot ec2 instance
                logger.info(f"Rebooting ec2 instance {i}")
                ec2_client.reboot_instances(InstanceIds=[i])
                time.sleep(15)
            else:
                raise Exception("SSM command for timezone change failed")

    # Ensure the instances have ok status before proceeding
    ec2_client.get_waiter("instance_status_ok").wait(InstanceIds=instance_ids)

    return None
