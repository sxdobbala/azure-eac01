import json
import logging
import sys

from opa.api import vars, helpers
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
            source = http.get_request_parameter(event, "source")
            destination = http.get_request_parameter(event, "destination")
            delete_flag = (
                http.get_request_parameter(event, "deleteFlag", required=False) or False
            )

            if not isinstance(delete_flag, bool):
                raise exceptions.ApiInvalidParameter(
                    "Invalid value for deleteFlag. Valid values(bool): true or false. false, if not specified. "
                )

            cloudwatch_log_group = f"/opa/{vars.ENV_PREFIX}/opa_s3_folder_sync"

            response = ssm.sync_folders(
                instance_id, source, destination, cloudwatch_log_group, delete_flag
            )
            return http.success(response)

        else:
            return http.method_not_allowed({"GET", "POST"})

    except (
        exceptions.ApiMissingRequestParameter,
        exceptions.ApiInvalidParameter,
    ) as error:
        logger.exception(error)
        return http.bad_request(error.message)

    except Exception as error:
        logger.exception(error)
        return http.internal_server_error()
