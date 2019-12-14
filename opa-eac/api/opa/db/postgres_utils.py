"""
Postgres utility functions
"""

# pylint: disable=import-error


import psycopg2


def get_connection(host, port, database, username, password):
    conn = psycopg2.connect(
        host=host,
        port=port,
        database=database,
        user=username,
        password=password,
        sslmode="require",
    )
    conn.autocommit = True

    return conn


def close_connection(conn):
    if conn is not None:
        conn.close()
