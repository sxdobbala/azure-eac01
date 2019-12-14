import boto3
import base64
import os
import random
import string
import logging
import json
import time
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
default_task_payload = {"status": "success"}

def run_script(
    instance_id,
    script_runtime,
    script_name,
    script_args,
    cloudwatch_log_group,
    sns_role_arn=None,
    sns_topic_arn=None,
    task_token=None,
    task_payload=default_task_payload,
):
    # only allow python3 and shell to execute commands for now
    if script_runtime not in set(["python3", "sh", "echo"]):
        raise Exception(f"{script_runtime} is not a valid runtime")

    command_args = " ".join(script_args)
    command_text = f"{script_runtime} {script_name} {command_args}"

    # the code below appends "&& success_action || failure_action" to the command_text
    # that way the ssm command is wrapped into shell pattern so we can notify sfn task about the script status.
    # the pattern "the_command && success_action || failure_action" will behave the following way:
    # success_action will be executed only if the_command completed successfully, otherwise skipped
    # failure_action will be executed only if the_command failed, otherwise skipped
    # task_payload is whatever you expect to see as output from the task within step function. It has to be in json format
    if not is_none_or_empty(task_token):
        escaped_json = json.dumps(task_payload).replace('"', '\\"')
        task_success = f"aws stepfunctions send-task-success --task-token {task_token} --region {os.environ['AWS_REGION']} --task-output \"{escaped_json}\""
        task_failure = f"aws stepfunctions send-task-failure --task-token {task_token} --region {os.environ['AWS_REGION']}"
        command_text += (f" && {task_success} || {task_failure}")

    return send_command(
        instance_id, command_text, cloudwatch_log_group, sns_role_arn, sns_topic_arn
    )


def sync_folders(
    instance_id, source, destination, cloudwatch_log_group, delete_flag=False
):
    extra_params = "--delete" if delete_flag else ""
    command_text = f"aws s3 sync {source} {destination} {extra_params}"

    return send_command(instance_id, command_text, cloudwatch_log_group)


def send_command(
    instance_id,
    command_text,
    cloudwatch_log_group,
    sns_role_arn=None,
    sns_topic_arn=None,
):
    logger.info(f"Sending ssm command...")
    logger.info(f"instance_id: {instance_id}")
    logger.info(f"command_text: {command_text}")
    logger.info(f"cloudwatch_log_group: {cloudwatch_log_group}")
    logger.info(f"sns_role_arn: {sns_role_arn}")
    logger.info(f"sns_topic_arn: {sns_topic_arn}")

    ssm = boto3.client("ssm")

    if is_none_or_empty(sns_role_arn) or is_none_or_empty(sns_topic_arn):
        response = ssm.send_command(
            InstanceIds=[instance_id],
            DocumentName="AWS-RunShellScript",
            Parameters={"commands": [command_text], "executionTimeout": ["172800"]},
            CloudWatchOutputConfig={
                "CloudWatchLogGroupName": cloudwatch_log_group,
                "CloudWatchOutputEnabled": True,
            },
        )
    else:
        response = ssm.send_command(
            InstanceIds=[instance_id],
            DocumentName="AWS-RunShellScript",
            Parameters={"commands": [command_text], "executionTimeout": ["172800"]},
            CloudWatchOutputConfig={
                "CloudWatchLogGroupName": cloudwatch_log_group,
                "CloudWatchOutputEnabled": True,
            },
            ServiceRoleArn=sns_role_arn,
            NotificationConfig={
                "NotificationArn": sns_topic_arn,
                "NotificationEvents": ["Success", "Failed"],
            },
        )

    logger.info(response)
    return response


def get_command_status(instance_id, command_id, include_logs=False):
    logger.info(f"Getting status of command {command_id} on instance {instance_id}")

    ssm = boto3.client("ssm")
    response = ssm.get_command_invocation(CommandId=command_id, InstanceId=instance_id)
    logger.info(response)

    if include_logs:
        # get cloudwatch execution logs for the given command_id and append to the response
        response["ExecutionLogs"] = get_invocation_logs(response)

    return response


def poll_command_response(instance_id, command_id):
    while True:
        time.sleep(5)

        command_response = get_command_status(instance_id, command_id)
        status = command_response["Status"]
        output = command_response["StandardOutputContent"].strip()

        if status not in ["Pending", "InProgress", "Delayed"]:
            break

    return status, output


def poll_command_status(instance_id, command_id):
    return poll_command_response(instance_id, command_id)[0] == "Success"


def poll_command_output(instance_id, command_id):
    return poll_command_response(instance_id, command_id)[1]


def get_parameter(key, decrypt=True):
    ssm = boto3.client("ssm")
    ssm_response = ssm.get_parameter(Name=key, WithDecryption=decrypt)
    return ssm_response["Parameter"]["Value"]


def put_parameter(key, value, type="SecureString", overwrite=True):
    ssm = boto3.client("ssm")
    ssm.put_parameter(Name=key, Value=value, Type=type, Overwrite=overwrite)


def is_none_or_empty(value):
    return value is None or value == ""


def get_invocation_logs(command_invocation_response):
    result = {}

    response = (
        json.loads(command_invocation_response)
        if isinstance(command_invocation_response, str)
        else command_invocation_response
    )

    if "CloudWatchOutputConfig" not in response:
        return result

    if "CloudWatchOutputEnabled" not in response["CloudWatchOutputConfig"]:
        return result

    if str(response["CloudWatchOutputConfig"]["CloudWatchOutputEnabled"]) != "True":
        return result

    log_group_name = response["CloudWatchOutputConfig"]["CloudWatchLogGroupName"]
    command_id = response["CommandId"]
    streams = get_log_stream_names(log_group_name, command_id)

    if streams:
        for log_stream_name in streams:
            log_events = get_log_events(log_group_name, log_stream_name)
            if log_events:
                result[log_stream_name] = log_events

    return result


def get_log_stream_names(log_group_name, log_stream_prefix):
    try:
        cw = boto3.client("logs")
        streams = cw.describe_log_streams(
            logGroupName=log_group_name, logStreamNamePrefix=log_stream_prefix
        )

        return list(stream["logStreamName"] for stream in streams["logStreams"])

    except Exception as error:
        logger.exception(error)
        return None


def get_log_events(log_group_name, log_stream_name):
    try:
        cw = boto3.client("logs")
        logs = cw.get_log_events(
            logGroupName=log_group_name, logStreamName=log_stream_name
        )

        return logs

    except Exception as error:
        logger.exception(error)
        return None
