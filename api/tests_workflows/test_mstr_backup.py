import pytest  # pylint: disable=import-error
import json
import logging
import boto3
import time
import string
import random
import os
from tests_workflows import workflow_utils as workflows

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

ENV_PREFIX = os.environ["ENV_PREFIX"]
MSTR_BACKUP_WORKFLOW_NAME = f"{ENV_PREFIX}-mstr-backup-sfn"
MSTR_BACKUP_WORKFLOW_ARN = (
    f"arn:aws:states:us-east-1:760182235631:stateMachine:{MSTR_BACKUP_WORKFLOW_NAME}"
)

MSTR_BACKUP_WORKFLOW_PAYLOAD_WITHOUT_CLIENT_ID = """
{
  "clientId": ""
}
"""


MSTR_BACKUP_WORKFLOW_PAYLOAD_WITH_CLIENT_ID = """
{
  "clientId": "h000166_d01"
}
"""


def test_mstr_backup_workflow_without_client_id():
    """ Invoke MSTR backup workflow without any client id """

    sfn_arn = MSTR_BACKUP_WORKFLOW_ARN
    sfn_name = f"{MSTR_BACKUP_WORKFLOW_NAME}-ci-{workflows.generate_random_string(10)}"
    sfn_payload = MSTR_BACKUP_WORKFLOW_PAYLOAD_WITHOUT_CLIENT_ID

    workflows.assert_workflow(sfn_arn, sfn_name, sfn_payload)


def test_mstr_backup_workflow_with_client_id():
    """ Invoke MSTR backup workflow with a valid client id """

    sfn_arn = MSTR_BACKUP_WORKFLOW_ARN
    sfn_name = f"{MSTR_BACKUP_WORKFLOW_NAME}-ci-{workflows.generate_random_string(10)}"
    sfn_payload = MSTR_BACKUP_WORKFLOW_PAYLOAD_WITH_CLIENT_ID

    workflows.assert_workflow(sfn_arn, sfn_name, sfn_payload)
