import json
import logging
import sys
import boto3

from opa.api import vars, helpers
from opa.db import postgres
from opa.utils import http, ssm

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

OPA_MASTER_SCHEMA = """CREATE TABLE IF NOT EXISTS client_config
(
    client_id character varying(100) NOT NULL,
    config_key character varying(200) NOT NULL,
    config_value text,
    create_time timestamp NOT NULL DEFAULT now(),
    last_update_time timestamp NOT NULL DEFAULT now(),
    CONSTRAINT pk_client_config PRIMARY KEY (client_id, config_key)
);"""


def lambda_handler(event, context):
    http.log_input(logger, event, context)

    conn = None

    try:
        conn = helpers.get_opa_master_connection()
        create_schema(conn)
        return http.success("Schema created.")

    except Exception as error:
        logger.exception(error)
        return http.internal_server_error()

    finally:
        postgres.close_connection(conn)


def create_schema(conn):
    with conn.cursor() as cur:
        cur.execute(OPA_MASTER_SCHEMA)

