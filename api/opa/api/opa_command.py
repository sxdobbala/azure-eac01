import json
import logging
import sys

from opa.utils import exceptions, http, ssm


logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    http.log_input(logger, event, context)

    try:
        operation = event["httpMethod"]

        if operation == "GET":
            instance_id = http.get_request_parameter(event, "instanceId")
            command_id = http.get_request_parameter(event, "commandId")

            response = ssm.get_command_status(instance_id, command_id)
            return http.success(response)

        elif operation == "POST":
            instance_id = http.get_request_parameter(event, "instanceId")
            script_runtime = http.get_request_parameter(event, "scriptRuntime")
            script_name = http.get_request_parameter(event, "scriptName")
            script_args = http.get_request_parameter(event, "scriptArgs")
            cloudwatch_log_group = http.get_request_parameter(
                event, "cloudwatchLogGroup"
            )
            sns_role_arn = http.get_request_parameter(
                event, "snsRoleArn", required=False
            )
            sns_topic_arn = http.get_request_parameter(
                event, "snsTopicArn", required=False
            )

            response = ssm.run_script(
                instance_id,
                script_runtime,
                script_name,
                script_args,
                cloudwatch_log_group,
                sns_role_arn,
                sns_topic_arn,
            )
            return http.success(response)

        else:
            return http.method_not_allowed({"GET", "POST"})

    except exceptions.ApiMissingRequestParameter as error:
        logger.exception(error)
        return http.bad_request(error.message)

    except Exception as error:
        logger.exception(error)
        return http.internal_server_error()
