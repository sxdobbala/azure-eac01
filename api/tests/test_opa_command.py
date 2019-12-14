import pytest  # pylint: disable=import-error
import json
import logging
import time

from opa.api import opa_command

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

test_post = """
{
  "httpMethod": "POST",
  "body": {
    "instanceId": "i-033dc99b6b35c49e0",
    "scriptRuntime": "python3",
    "scriptName": "/home/ssm-user/test_script.py",
    "scriptArgs": [
      "testing..."
    ],
    "cloudwatchLogGroup": "/opa/ci/opa_command/"
  }
}
"""


test_get = """
{
  "httpMethod": "GET",
  "queryStringParameters": {
    "instanceId": "i-033dc99b6b35c49e0",
    "commandId": ""
  }
}
"""


def test_opa_command():
    """ OPA command lambda should invoke a script OR return invocation status """

    event = json.loads(test_post)
    response = opa_command.lambda_handler(event, None)
    logger.debug(response)
    assert response["statusCode"] == "200"

    time.sleep(10)

    command_id = json.loads(response["body"])["Command"]["CommandId"]
    event = json.loads(test_get)
    event["queryStringParameters"]["commandId"] = command_id
    response = opa_command.lambda_handler(event, None)
    logger.debug(response)
    assert response["statusCode"] == "200"
