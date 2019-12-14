import logging

from opa.db import postgres
from opa.utils import exceptions

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def load_config(client_id, config_key, conn):
    data = {}
    cur = conn.cursor()

    if config_key is None:
        sql = "SELECT config_key, config_value FROM client_config WHERE client_id = %s"
        cur.execute(sql, (client_id,))
    else:
        sql = "SELECT config_key, config_value FROM client_config WHERE client_id = %s AND config_key = %s"
        cur.execute(sql, (client_id, config_key))

    for key, value in cur.fetchall():
        data[key] = value

    cur.close()

    if len(data) == 0:
        if config_key is None:
            raise exceptions.ApiConfigSettingNotFound(
                f"Config settings for client {client_id} not found."
            )
        else:
            raise exceptions.ApiConfigSettingNotFound(
                f"Config setting {config_key} for client {client_id} not found."
            )

    return data


def save_config(client_id, data, conn):
    sql = """INSERT INTO client_config(client_id, config_key, config_value)
                VALUES(%s, %s, %s)
                ON CONFLICT (client_id, config_key)
                DO
                    UPDATE
                        SET config_value = EXCLUDED.config_value,
                            last_update_time = now()"""

    cur = conn.cursor()

    for key, value in data.items():
        cur.execute(sql, (client_id, key, clean_text(value)))

    conn.commit()
    cur.close()


def delete_config(client_id, config_key, conn):
    cur = conn.cursor()

    if config_key is None:
        sql = "DELETE FROM client_config WHERE client_id = %s"
        cur.execute(sql, (client_id,))
    else:
        sql = "DELETE FROM client_config WHERE client_id = %s AND config_key = %s"
        cur.execute(sql, (client_id, config_key))

    count = cur.rowcount

    conn.commit()
    cur.close()

    return count


def lookup_client_ids(config_key, config_value, conn):
    client_ids = []
    cur = conn.cursor()

    sql = "SELECT client_id FROM client_config WHERE config_key = %s and config_value = %s"
    cur.execute(sql, (config_key, config_value))

    for row in cur.fetchall():
        client_ids.append(row[0])

    cur.close()

    return client_ids


def clean_text(value):
    # outputs from step functions is wrapped in \" which needs to be removed prior to use in lambdas
    return value.replace('"', "").replace("\\", "")
