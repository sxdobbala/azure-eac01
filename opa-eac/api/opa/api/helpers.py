import boto3
import logging
import os

from opa.api import vars
from opa.db import postgres
from opa.utils import api, ssm, exceptions, config

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def get_opa_master_connection():
    return postgres.get_connection(
        vars.OPA_MASTER_HOST,
        vars.OPA_MASTER_PORT,
        vars.OPA_MASTER_DATABASE,
        vars.OPA_MASTER_USER,
        ssm.get_parameter(vars.OPA_MASTER_PASSWORD_KEY),
    )


def get_redshift_client_database(client_id):
    return client_id.lower()


def get_redshift_client_username(client_id):
    return f"{client_id}_user".lower()


def get_mstr_password_key(env_id):
    return f"/{env_id}/MSTR_PASSWORD"


# TODO: update this method to get instance_id from SSM param store under /{env_id}/instance_id
def get_instance_id(env_id):
    return get_stack_output_value(env_id, "PlatformInstance01")


def get_instance_ids(env_id):
    ec2 = boto3.resource("ec2")

    return list(
        map(
            lambda i: i.instance_id,
            ec2.instances.filter(
                Filters=[{"Name": "tag:Customer", "Values": [env_id]}]
            ),
        )
    )


def get_cube_builder_username(client_id):
    return f"{client_id}_Cube Builder"


def get_cube_builder_password_key(client_id, env_id):
    return f"{env_id}.{client_id}.cube-builder-password"


def get_stack_output_value(stack_name, key):
    cf = boto3.client("cloudformation")
    result = cf.describe_stacks(StackName=stack_name)
    outputs = result["Stacks"][0]["Outputs"]
    value = [x["OutputValue"] for x in outputs if x["OutputKey"] == key][0]
    logger.debug(f"Output value for {key} key is: {value}")

    if not value:
        raise Exception(f"Key {key} not found in stack {stack_name} outputs")

    return value


def get_redshift_details(redshift_id):
    client = boto3.client("redshift")
    result = client.describe_clusters(ClusterIdentifier=redshift_id)
    cluster = result["Clusters"][0]

    return {
        "host": cluster["Endpoint"]["Address"],
        "port": cluster["Endpoint"]["Port"],
        "database": cluster["DBName"],
        "username": cluster["MasterUsername"],
    }


# TODO: update this method to use DynamoDB for storage of tokens
# ideally we should store execution_id (from SFN), token, command_id/deployment_id, instance_id
def save_token(id, event):
    if "token" in event:
        key = f"/{vars.ENV_PREFIX}/{id}"
        value = event["token"]
        ssm.put_parameter(key, value, "String")
        logger.info(f"Saved to SSM: {key} = {value}")


def clean_text(value):
    # outputs from step functions is wrapped in \" which needs to be removed prior to use in lambdas
    return value.replace('"', "").replace("\\", "")