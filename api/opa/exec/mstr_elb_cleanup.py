import boto3
import logging
import os
import sys
import re

from botocore.exceptions import ClientError
from opa.api import helpers
from opa.utils import api

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

ENV_PREFIX = api.get_os_environ_value("ENV_PREFIX")


def lambda_handler(event, context):
    logger.info(f"Received event: {event}")

    # get env_id, making sure to strip out quotes if there are any
    env_id = helpers.clean_text(event)

    # Find default load balancer created by MicroStrategy and delete HTTPS 443 listener
    delete_listener_for_default_app_elb(env_id)

    # Delete the ELBs created by MSTR stack since we're no longer using them
    delete_obsolete_mstr_elbs(env_id)


def delete_listener_for_default_app_elb(env_id):
    # Expect to find a default app load balancer with this name created by MicroStrategy
    app_elb_name = env_id + "-appelb"
    lb_arn = find_lb_arn(app_elb_name)

    if lb_arn is None:
        logger.info(f"No default MSTR app-elb found: {app_elb_name}; nothing to delete")
        return

    # Find listener for HTTPS protocol and port 443
    listener_arn = find_listener_arn(lb_arn, "HTTPS", 443)

    if listener_arn is None:
        logger.info(
            "No listener found for port 443 (https) on the default MSTR elb; nothing to delete"
        )
        return

    # Remove this listener to disassociate existing target group
    client = boto3.client("elbv2")
    client.delete_listener(ListenerArn=listener_arn)


def delete_obsolete_mstr_elbs(env_id):
    # use the "elbv2" client to delete the APP-ELB
    arn = find_lb_arn(f"{env_id}-appelb")

    if arn is not None:
        client = boto3.client("elbv2")
        client.delete_load_balancer(LoadBalancerArn=arn)

    # use the "elb" client to delete the "classic" ELB
    client = boto3.client("elb")
    client.delete_load_balancer(LoadBalancerName=f"{env_id}-elb")


def find_lb_arn(app_elb_name):
    lb_arn = None
    client = boto3.client("elbv2")

    try:
        response = client.describe_load_balancers(Names=[app_elb_name])
        lb_arn = response.get("LoadBalancers")[0]["LoadBalancerArn"]

    except client.exceptions.LoadBalancerNotFoundException:
        logger.info(f"Load balancer {app_elb_name} not found")

    return lb_arn


def find_listener_arn(lb_arn, protocol, port):
    listener_arn = None
    client = boto3.client("elbv2")
    response = client.describe_listeners(LoadBalancerArn=lb_arn)
    listeners = response.get("Listeners")

    for listener in listeners:
        if listener["Protocol"] == protocol and listener["Port"] == port:
            listener_arn = listener["ListenerArn"]

    return listener_arn

