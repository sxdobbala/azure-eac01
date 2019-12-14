import json
import logging
import sys
import boto3
import os

from opa.api import vars, helpers
from opa.utils import api, config, exceptions, http, ssm, opamaster, constants

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info(f"Event received: {event}")

    env_id = helpers.clean_text(event["envId"])
    instance_id = helpers.get_instance_id(env_id)
    redshift_id = event["redshiftId"]

    logger.info("Updating EC2 security groups and attaching policy")
    associate_redshift_with_ec2(redshift_id, instance_id)

    return "Success"


def associate_redshift_with_ec2(redshift_id, instance_id):
    sg_id = ssm.get_parameter(f"redshift.{redshift_id}.sg")
    logger.info(f"sg_id = {sg_id}")

    ec2 = boto3.resource("ec2")

    for i in get_ec2_cluster_instances(instance_id):
        ec2_instance = ec2.Instance(i.instance_id)
        attach_sg(ec2_instance, sg_id)
        attach_policy(ec2_instance, redshift_id)

    return None


def attach_sg(ec2_instance, sg_id):
    ec2_groups = [sg["GroupId"] for sg in ec2_instance.security_groups]
    logger.info(f"Original EC2 Security Groups: {ec2_groups}")

    if sg_id not in ec2_groups:
        ec2_groups.append(sg_id)
        ec2_instance.modify_attribute(Groups=ec2_groups)
    logger.info(f"Updated EC2 Security Groups: {ec2_groups}")

    return None


def attach_policy(ec2_instance, redshift_id):
    account_id = boto3.client("sts").get_caller_identity().get("Account")
    policy_arn = f"arn:aws:iam::{account_id}:policy/{redshift_id}-AccessPolicy"

    instance_profile_arn = ec2_instance.iam_instance_profile["Arn"]
    instance_profile_name = instance_profile_arn.split("/")[-1]
    iam = boto3.client("iam")
    instance_profile = iam.get_instance_profile(
        InstanceProfileName=instance_profile_name
    )
    ec2_role = instance_profile["InstanceProfile"]["Roles"][0][
        "RoleName"
    ]  # collection but only one role allowed

    iam.attach_role_policy(RoleName=ec2_role, PolicyArn=policy_arn)
    logger.info(f"Attached {policy_arn} to role {ec2_role}")

    return None


def get_ec2_cluster_instances(instance_id):
    # get one instance in the cluster
    ec2 = boto3.resource("ec2")
    ec2_instance = ec2.Instance(instance_id)

    # find the stack this instance was created by
    stack_name = next(t["Value"] for t in ec2_instance.tags if t["Key"] == "Customer")

    # then find all instances created by the same stack
    all_instances = ec2.instances.filter(
        Filters=[{"Name": "tag:Customer", "Values": [stack_name]}]
    )
    return all_instances
