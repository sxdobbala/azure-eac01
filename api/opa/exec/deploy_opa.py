import logging
import os
import time

import boto3
from opa.utils import api
from opa.api import helpers, vars

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info(f"Event received: {event}")

    env_id = helpers.clean_text(event["envId"])
    release_id = event["releaseId"]

    source_bucket_id = api.get_os_environ_value("S3_BUCKET_ID")
    codedeploy_appname = api.get_os_environ_value("CODEDEPLOY_APPLICATION")
    opa_release_s3_prefix = api.get_os_environ_value("OPA_RELEASE_S3_PREFIX")

    opa_codedeploy_key = (
        f"{opa_release_s3_prefix}/{release_id}/oap-mstr-web-deployment.zip"
    )
    logger.info(f"opa_codedeploy_key: {opa_codedeploy_key}")

    codedeploy = boto3.client("codedeploy")
    response = codedeploy.create_deployment(
        applicationName=codedeploy_appname,
        deploymentGroupName=api.get_os_environ_value(
            "DEPLOYMENT_GROUP_NAME_FORMATTER"
        ).format(env_id),
        revision={
            "revisionType": "S3",
            "s3Location": {
                "bucket": source_bucket_id,
                "key": opa_codedeploy_key,
                "bundleType": "zip",
            },
        },
        description=f"Deploy OPA to {env_id}",
        fileExistsBehavior="OVERWRITE",
    )

    deployment_id = response["deploymentId"]
    logger.info(deployment_id)

    # save token if present
    helpers.save_token(deployment_id, event)

    return deployment_id


# main method to test from command line
if __name__ == "__main__":
    lambda_handler({"envId": "env-12345"}, None)
