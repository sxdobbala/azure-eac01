import pytest  # pylint: disable=import-error
import json
import logging
from opa.api import opa_s3_folder_sync

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

test_post = """
{
  "httpMethod": "POST",
  "body": {
      "instanceId": "i-033dc99b6b35c49e0",
      "source": "s3://760182235631-opa-artifacts-opa/e2e-releases/release-9.0_v1/mstr-content/release-9.0/mstr/components",
      "destination": "/home/mstr/s3_sync_test",
      "deleteFlag": true
  }
}
"""

# Valid values for deleteFlag(bool): true/false
test_post_invalid_delete_flag = """
{
  "httpMethod": "POST",
  "body": {
      "instanceId": "doesntmatter",
      "source": "doesntmatter",
      "destination": "doesntmatter",
      "deleteFlag": "true"
  }
}
"""

# Commenting out since it depends on correct values in payload and may not work for everyone ootb
# def test_opa_s3_folder_sync():
#     """ OPA s3_folder_sync lambda should sync """

#     event = json.loads(test_post)
#     response = opa_s3_folder_sync.lambda_handler(event, None)
#     logger.debug(response)
#     assert response["statusCode"] == "200"


def test_opa_s3_folder_sync_invalid_delete_flag():
    """ OPA s3_folder_sync lambda should return bad request on invalid deleteFlag """

    event = json.loads(test_post_invalid_delete_flag)
    response = opa_s3_folder_sync.lambda_handler(event, None)
    logger.debug(response)
    assert response["statusCode"] == "400"
