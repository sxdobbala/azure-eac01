import json
import logging

from opa.api import vars
from botocore.vendored import requests

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info(f"Event received: {event}")

    smoke_test_url = get_smoke_test_url(event)
    response = requests.get(smoke_test_url)

    if not response.ok:
        raise Exception(f"Smoke test failed: {response.text}")


def get_smoke_test_url(elb_path):
    switcher = {"dev": "dev", "qa": "qa", "stage": "stage", "prod": ""}
    url_prefix = switcher.get(vars.ENV_PREFIX.lower(), "dev")
    return f"https://{url_prefix}cloud.performanceanalytics.optum.com/{elb_path}/MicroStrategy/servlet/mstrWeb?disableOkta"
