import pytest  # pylint: disable=import-error
import json
import logging
import time

from unittest.mock import patch

from opa.api import opa_master_schema
from opa.api import opa_client_onboarding
from opa.api import opa_data_load
from opa.api import opa_mstr_backup
from opa.api import opa_mstr_migration
from opa.api import opa_post_data_load
from tests.test_opa_master import opa_master_setup

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

test_post = """
{
  "httpMethod": "POST",
  "body": {
    "clientId": "CI"
  }
}
"""


test_get = """
{
  "httpMethod": "GET",
  "queryStringParameters": {
    "clientId": "CI"
  },
  "body": {}
}
"""


test_data_load_custom_script = """
{
  "httpMethod": "POST",
  "body": {
    "clientId": "CI",
    "s3_prefix": "s3_prefix",
    "dataload_type": "monthly",
    "scriptName": "/home/ssm-user/test_opa_data_load.py",
    "scriptRuntime": "python3"
  }
}
"""

test_data_load_opa_master_script = """
{
  "httpMethod": "POST",
  "body": {
    "clientId": "CI",
    "s3_prefix": "s3_prefix",
    "dataload_type": "monthly"
  }
}
"""

test_post_data_load = """
{
  "httpMethod": "POST",
  "body": {
    "clientId": "CI",
    "dataload_type": "monthly",
    "scriptName": "/home/ssm-user/test_opa_post_data_load.py",
    "scriptRuntime": "python3"
  }
}
"""

test_mstr_migration = """
{
  "envId": "env-164062"
}
"""


test_mstr_backup = """
{
  "clientId": "CI",
  "scriptName": "/home/ssm-user/test_opa_mstr_backup.py",
  "scriptRuntime": "python3"
}
"""


test_client_onboarding_new_client = """
{
  "clientId": "CI_not_in_OPA_Master",
  "clientName": "",
  "clientHasEGR": "",
  "envId": "env-164062",
  "redshiftId": "opadevredshift-1-redshift-cluster",
  "scriptName": "/home/ssm-user/test_opa_client_onboarding.py",
  "scriptRuntime": "python3"
}
"""


test_client_onboarding_stack_rotation = """
{
  "clientId": "CI",
  "envId": "env-164062",
  "redshiftId": "opadevredshift-1-redshift-cluster",
  "scriptName": "/home/ssm-user/test_opa_client_onboarding.py",
  "scriptRuntime": "python3"
}
"""


def invoke_lambda_post(lambda_module, test_event=test_post):
    """ OPA lambda should invoke target process """

    event = json.loads(test_event) if test_event else None
    response = lambda_module.lambda_handler(event, None)
    logger.debug(response)
    assert response["statusCode"] == "200"


def invoke_lambda_get(lambda_module, test_event=test_get):
    """ OPA lambda should return invocation status """

    event = json.loads(test_event)
    response = lambda_module.lambda_handler(event, None)
    logger.debug(response)

    # Check if http response first
    if "statusCode" in response:
        assert response["statusCode"] == "200"
        assert json.loads(response["body"])["Status"] == "Success"
    # Verify ssm command response
    else:
        assert response["Status"] == "Success"


def invoke_lambda(lambda_module, test_post_event=test_post, seconds=10):
    invoke_lambda_post(lambda_module, test_post_event)
    time.sleep(seconds)
    invoke_lambda_get(lambda_module)


def test_opa_client_onboarding_new_client(opa_master_setup):
    event = json.loads(test_client_onboarding_new_client)
    response = opa_client_onboarding.lambda_handler(event, None)
    logger.debug(response)
    assert response, "Command id expected"


def test_opa_client_onboarding_stack_rotation(opa_master_setup):
    event = json.loads(test_client_onboarding_stack_rotation)
    response = opa_client_onboarding.lambda_handler(event, None)
    logger.debug(response)
    assert response, "Command id expected"


def test_opa_data_load_custom_script(opa_master_setup):
    invoke_lambda(opa_data_load, test_data_load_custom_script, 45)


def test_opa_data_load_opa_master_script(opa_master_setup):
    invoke_lambda(opa_data_load, test_data_load_opa_master_script, 30)


def test_opa_master_schema(opa_master_setup):
    invoke_lambda_post(opa_master_schema, None)

@patch("opa.utils.ssm.poll_command_status")
@patch("opa.utils.ssm.run_script")
def test_opa_mstr_backup(run_script, poll_command_status, opa_master_setup):
    run_script.return_value = {"Command": {"CommandId": "12345"}}

    event = json.loads(test_mstr_backup)
    response = opa_mstr_backup.lambda_handler(event, None)

    assert response.endswith(".tar.gz")
    args = run_script.call_args[0]

    assert "--mstr-username mstr" in args[3]

def test_opa_mstr_migration(opa_master_setup):
    event = json.loads(test_mstr_migration)
    response = opa_mstr_migration.lambda_handler(event, None)
    logger.debug(response)
    assert response, "Command id expected"


def test_opa_post_data_load(opa_master_setup):
    invoke_lambda(opa_post_data_load, test_post_data_load, 30)

