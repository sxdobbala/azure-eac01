import json
import logging
import os
import re
import sys
import time
import boto3

from opa.utils import api, ssm, tagging
from opa.api import helpers, vars

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info(f"Received event: {event}")

    # get input params
    env_id = helpers.clean_text(event["envId"])

    # Set MSTR password in SSM store
    set_password_ssm(env_id)

    # Apply tags to MSTR resources that could not be applied with terraform
    apply_tags(env_id)

    # Attach dataloader egress SG to EC2
    associate_dataloader_egress_sg_with_ec2(env_id)

    # Run deployment
    deployment_id = run_deployment(env_id)

    # save token if present
    helpers.save_token(deployment_id, event)

    return deployment_id


def set_password_ssm(env_id):
    logger.info("Setting password in SSM Parameter Store...")

    platform_instance_id = helpers.get_stack_output_value(env_id, "PlatformInstance01")
    client = boto3.client("ssm")

    region = boto3.session.Session().region_name
    response = client.send_command(
        InstanceIds=[platform_instance_id],
        DocumentName="AWS-RunShellScript",
        Parameters={
            "commands": [
                f'aws ssm put-parameter --region {region} --name /{env_id}/MSTR_PASSWORD --overwrite --type SecureString --value `xmllint --xpath "string(user-mapping/authorize/@password)" /opt/guacamole/user-mapping.xml`'
            ]
        },
    )
    command_id = response["Command"]["CommandId"]
    logger.info(f"command_id = {command_id}")

    status = ssm.poll_command_status(platform_instance_id, command_id)

    if status:
        logger.info("SSM command to set password succeeded")
    else:
        raise Exception("SSM command to set password failed")


def associate_dataloader_egress_sg_with_ec2(env_id):
    sg_id = api.get_os_environ_value("DATALOADER_EGRESS_SG_ID")
    logger.info(f"sg_id = {sg_id}")

    ec2 = boto3.resource("ec2")
    all_instances = ec2.instances.filter(
        Filters=[{"Name": "tag:Customer", "Values": [env_id]}]
    )

    for i in all_instances:
        ec2_instance = ec2.Instance(i.instance_id)
        attach_sg(ec2_instance, sg_id)

    return None


def attach_sg(ec2_instance, sg_id):
    ec2_groups = [sg["GroupId"] for sg in ec2_instance.security_groups]
    logger.info(f"Original EC2 Security Groups: {ec2_groups}")

    if sg_id not in ec2_groups:
        ec2_groups.append(sg_id)
        ec2_instance.modify_attribute(Groups=ec2_groups)
    logger.info(f"Updated EC2 Security Groups: {ec2_groups}")

    return None


def run_deployment(env_id):
    codedeploy = boto3.client("codedeploy")
    source_bucket_id = api.get_os_environ_value("S3_BUCKET_ID")
    mstr_linux_codedeploy_key = api.get_os_environ_value(
        "MSTR_POSTINSTALL_CODEDEPLOY_KEY"
    )
    applicationName = api.get_os_environ_value("MSTR_POSTINSTALL_CODEDEPLOY_APP_NAME")
    deployment_group_env_prefix = ssm.get_parameter(f"/{env_id}/env_prefix")
    response = codedeploy.create_deployment(
        applicationName=applicationName,
        deploymentGroupName=f"{deployment_group_env_prefix}-{env_id}-platform",
        revision={
            "revisionType": "S3",
            "s3Location": {
                "bucket": source_bucket_id,
                "key": mstr_linux_codedeploy_key,
                "bundleType": "zip",
            },
        },
        description="MSTR Linux Post Deployment",
        fileExistsBehavior="OVERWRITE",
    )
    logger.info("linux deployment")

    deployment_id = response["deploymentId"]
    logger.info(deployment_id)

    return deployment_id


def apply_tags(env_id):
    global_tags = api.get_os_environ_value("GLOBAL_TAGS")

    #load & update tags dict
    tags = json.loads(global_tags)
    tags["optum:environment"] = ssm.get_parameter(f"/{env_id}/env_prefix")
    tags["terraform"] = "false"

    elb_path = ssm.get_parameter(f"/{env_id}/elb_path")
    if elb_path:
        tags["optum:elb-path"] = elb_path
    else:
        logger.error(f"/{env_id}/elb_path not found in SSM")

    #apply tags
    tagging.apply_tags_to_ec2(env_id, tags)
