"""
Redshift utility functions
"""

# pylint: disable=import-error

import boto3
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


def get_cluster_credentials(username, cluster_identifier):
    client = boto3.client("redshift")
    creds = client.get_cluster_credentials(
        DbUser=username, ClusterIdentifier=cluster_identifier
    )

    return creds


def create_database(conn, database, username):
    if database_exists(conn, database):
        return

    sql = f"create database {database.lower()} with owner {username.lower()}"

    with conn.cursor() as cursor:
        cursor.execute(sql)


def database_exists(conn, database):
    sql = f"select * from pg_database where datname = '{database.lower()}'"

    with conn.cursor() as cursor:
        cursor.execute(sql)
        return cursor.fetchone()


def create_user(conn, username):
    if username_exists(conn, username):
        return

    sql = f"create user {username.lower()} with password DISABLE"

    with conn.cursor() as cursor:
        cursor.execute(sql)


def alter_user_search_path(conn, username, search_path):
    if not username_exists(conn, username):
        return

    sql = f"alter user {username.lower()} set search_path to {search_path}"

    with conn.cursor() as cursor:
        cursor.execute(sql)


def alter_user_password(conn, username, password):
    if not username_exists(conn, username):
        return

    sql = f"alter user {username.lower()} password '{password}'"

    with conn.cursor() as cursor:
        cursor.execute(sql)


def username_exists(conn, username):
    sql = f"select * from pg_user where usename = '{username.lower()}'"

    with conn.cursor() as cursor:
        cursor.execute(sql)
        if cursor.fetchone():
            return True
        else:
            return False


def db_group_exists(conn, group_name):
    sql = f"select * from pg_group where groname = '{group_name}'"

    with conn.cursor() as cursor:
        cursor.execute(sql)
        return cursor.fetchone()


def create_db_user_group(conn, group_name):
    if db_group_exists(conn, group_name):
        return

    sql = f"create group {group_name}"
    with conn.cursor() as cursor:
        cursor.execute(sql)
