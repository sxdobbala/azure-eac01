import json
import opa.utils.exceptions
from datetime import datetime


class JSONEncoderWithISODates(json.JSONEncoder):
    def default(self, o):  # pylint: disable=E0202
        if isinstance(o, datetime):
            return o.isoformat()

        return super().default(o)


def get_http_response(statusCode, content=""):
    return {
        "statusCode": statusCode,
        "body": to_json(content),
        "headers": {"Content-Type": "application/json"},
    }


def success(content=None):
    return get_http_response("200", content)


def bad_request(content=None):
    return get_http_response("400", content)


def not_found(content=None):
    return get_http_response("404", content)


def method_not_allowed(allowed_methods):
    response = get_http_response("405", "Method not allowed")
    response["headers"]["Allow"] = ",".join(allowed_methods)
    return response


def internal_server_error(content="Internal Server Error"):
    # intentional: allow content to be passed in but ignore it
    return get_http_response("500", "Internal Server Error")


def to_json_ready(content):
    return content if content is not None else ""


def to_json(content):
    json_ready_content = to_json_ready(content)
    return (
        content
        if isinstance(content, str)
        else json.dumps(json_ready_content, cls=JSONEncoderWithISODates)
    )


def get_body(event):
    return (
        json.loads(event["body"]) if isinstance(event["body"], str) else event["body"]
    )


def get_request_parameter(event, parameter_name, required=True):
    parameter_value = None
    operation = event["httpMethod"]

    if operation == "GET":
        parameter_value = (
            event["queryStringParameters"][parameter_name]
            if parameter_name in event["queryStringParameters"]
            else None
        )
    else:
        payload = get_body(event)
        parameter_value = payload[parameter_name] if parameter_name in payload else None

    if required and parameter_value is None:
        raise opa.utils.exceptions.ApiMissingRequestParameter(
            f"Missing required {operation} request parameter '{parameter_name}'"
        )

    return parameter_value


def log_input(logger, event, context):
    logger.info(f"Received event: {event}")
    logger.info(f"Received context: {context}")
