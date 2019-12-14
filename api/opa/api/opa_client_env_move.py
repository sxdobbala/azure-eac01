import json
import logging

from opa.api import vars, helpers
from opa.utils import config, exceptions, opamaster, ssm, tagging
from botocore.vendored import requests

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info(f"Event received: {event}")

    old_env_id = helpers.clean_text(event["oldEnvId"])
    env_id = helpers.clean_text(event["envId"])

    migrate_opa_master(old_env_id, env_id)

    # TODO: commenting this out for now - SSM params migration needs to be done prior to WAR deployment
    # migrate_ssm_parameters(old_env_id, env_id)

    migrate_client_tag(old_env_id, env_id)
    return "Success"


def migrate_opa_master(old_env_id, env_id):
    # find which clients were on the old_env_id stack
    conn = helpers.get_opa_master_connection()
    client_ids = opamaster.lookup_client_ids(config.ENV_ID, old_env_id, conn)
    logger.info(client_ids)

    # for each of the clients found, update their stack to be env_id
    if client_ids:
        for client_id in client_ids:
            opamaster.save_config(client_id, {config.ENV_ID: env_id}, conn)
            logger.info(f"Client {client_id} moved from {old_env_id} to {env_id}")


def migrate_ssm_parameters(old_env_id, env_id):
    migrate_parameter(f"/{old_env_id}/sso_okta_secret", f"/{env_id}/sso_okta_secret")
    migrate_parameter(
        f"/{old_env_id}/sso_esm_admin_password", f"/{env_id}/sso_esm_admin_password"
    )


def migrate_parameter(from_key, to_key):
    value = ssm.get_parameter(from_key)
    ssm.put_parameter(to_key, value)

def migrate_client_tag(old_env_id, env_id):
    tag_key_prefix = "optum:client:"
    
    #find corresponding tags from the old env
    tags = tagging.get_tags_with_key_prefix(old_env_id, tag_key_prefix)
    
    logger.info(f"tags: {tags}")
    #apply tag to the new env
    tagging.apply_tags_to_ec2(env_id, tags)