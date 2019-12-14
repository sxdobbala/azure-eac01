import json
import os
import boto3
import logging
import sys
import botocore.vendored.requests as requests

from datetime import datetime, timedelta
from opa.utils import api

S3_BUCKET = api.get_os_environ_value("S3_BUCKET")
S3_PREFIX = api.get_os_environ_value("S3_PREFIX")
REGISTRY_API_URL = api.get_os_environ_value("REGISTRY_API_URL")
RESPONSE_QUEUE_URL = api.get_os_environ_value("RESPONSE_QUEUE_URL")

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info(f"Received event: {event}")
    logger.info(f"Received context: {context}")

    # we don't know how long it takes to get results from the DataLoader registry API
    # so the request queue has been setup to supply a single record at a time to the lambda
    if len(event["Records"]) != 1:
        raise Exception("Unable to process. Exactly one record expected")

    record = event["Records"][0]
    body = json.loads(record["body"])
    logger.info(f"body: {body}")

    client_id = body["clientId"]
    registry_id = body["registryId"]
    tracking_id = body["trackingId"]

    logger.info(f"clientId: {client_id}")
    logger.info(f"registryId: {registry_id}")
    logger.info(f"trackingId: {tracking_id}")

    # build the registry request payload
    request_payload = build_registry_request_payload(client_id, registry_id)

    # retrieve the registry metadata from the DataLoader service
    data = retrieve_registry_data(
        client_id, registry_id, "registry/info", request_payload
    )
    metadata_s3_key = get_s3_key(client_id, registry_id, "metadata")
    upload_data_to_s3(data, metadata_s3_key)

    # retrieve the registry patient list from the DataLoader service
    data = retrieve_registry_data(
        client_id, registry_id, "registry/patients", request_payload
    )
    patients_s3_key = get_s3_key(client_id, registry_id, "patients")
    upload_data_to_s3(data, patients_s3_key)

    # send a message to the response queue so that LINK can grab the data from S3
    send_message_to_response_queue(
        client_id, registry_id, tracking_id, metadata_s3_key, patients_s3_key
    )

    return True


def build_registry_request_payload(client_id, registry_id):
    # DataLoader params are case-sensitive so if they get changed, we need to update them here

    db_info = {}
    db_info["clientId"] = client_id

    request = {}
    request["clientID"] = client_id
    request["registryID"] = registry_id
    request["dbInfo"] = db_info
    request["updatedBy"] = api.get_os_environ_value("AWS_LAMBDA_FUNCTION_NAME")

    return request


def retrieve_registry_data(client_id, registry_id, registry_method, request_payload):
    url = f"{REGISTRY_API_URL.rstrip('/')}/{registry_method}"
    headers = {"Content-Type": "application/json"}
    data = json.dumps(request_payload)

    # TODO: SSL-verification is turned off until DataLoader can be deployed with the correct certs
    response = requests.post(url=url, headers=headers, data=data, verify=False)

    if response.ok:
        logger.info(f"Success response {response}: {response.text}")
        return response.text
    else:
        logger.error(f"Error calling {url} with POST data: {data}")
        logger.error(f"Error response {response}: {response.text}")
        raise Exception(response.text)


def get_s3_key(client_id, registry_id, typeId):
    return f"{S3_PREFIX}/{client_id}/{client_id}.{registry_id}.{typeId}.json"


def upload_data_to_s3(data, s3_key):
    # let uploads expire in 24 hours
    expiration = datetime.now() + timedelta(hours=24)

    s3 = boto3.resource("s3")
    s3.Bucket(S3_BUCKET).put_object(
        Key=s3_key, Body=data.encode("utf-8"), Expires=expiration
    )
    return True


def send_message_to_response_queue(
    client_id, registry_id, tracking_id, metadata_key, patient_list_key
):
    data = {}
    data["clientId"] = client_id
    data["registryId"] = registry_id
    data["trackingId"] = tracking_id
    data["payloadLocation"] = S3_BUCKET
    data["metadataKey"] = metadata_key
    data["patientListKey"] = patient_list_key

    sqs = boto3.client("sqs")
    msg = json.dumps(data)
    response = sqs.send_message(QueueUrl=RESPONSE_QUEUE_URL, MessageBody=msg)
    logger.info(f"Message {msg} sent to queue {RESPONSE_QUEUE_URL}: {response}")
