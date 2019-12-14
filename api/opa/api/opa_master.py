import json
import logging
import sys
import boto3

from opa.api import vars, helpers
from opa.db import postgres
from opa.utils import exceptions, http, ssm, opamaster

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    http.log_input(logger, event, context)

    conn = None

    try:
        operation = event["httpMethod"]

        conn = helpers.get_opa_master_connection()

        if operation == "GET":
            client_id = http.get_request_parameter(event, "clientId")
            config_key = http.get_request_parameter(event, "configKey", required=False)
            content = opamaster.load_config(client_id, config_key, conn)
            return http.success(content)

        elif operation == "PUT":
            client_id = http.get_request_parameter(event, "clientId")
            data = http.get_request_parameter(event, "data")
            opamaster.save_config(client_id, data, conn)
            return http.success()

        elif operation == "DELETE":
            client_id = http.get_request_parameter(event, "clientId")
            config_key = http.get_request_parameter(event, "configKey", required=False)
            delete_count = opamaster.delete_config(client_id, config_key, conn)
            return http.success(delete_count)

        else:
            return http.method_not_allowed({"GET", "PUT", "DELETE"})

    except exceptions.ApiMissingRequestParameter as error:
        logger.exception(error)
        return http.bad_request(error.message)

    except exceptions.ApiConfigSettingNotFound as error:
        logger.exception(error)
        return http.not_found(error.message)

    except Exception as error:
        logger.exception(error)
        return http.internal_server_error()

    finally:
        postgres.close_connection(conn)
