import os
import subprocess
import pymysql.cursors


CREATE_DATABASE_QUERY = "CREATE DATABASE database_name"

DATABASE_EXISTENCE_QUERY = "SHOW DATABASES LIKE 'database_name'"

def get_db_connection_handle(host, database, port, user_name, password):
    try:
        db_handle = pymysql.connect(host=host,
                                    port=port,
                                    database = database,
                                    user = user_name,
                                    password = password,
                                    charset='utf8mb4',
                                    cursorclass=pymysql.cursors.DictCursor
                                   ) 

        return db_handle
    except Exception as e:
        print('An error occurred while creating connection to the database: {e}')
        raise Exception(e)


def create_if_not_exist_database(db_handle, database_name):
    try:
        is_database_exist = check_if_database_exist(db_handle, database_name)

        if not is_database_exist:
            create_database(db_handle, database_name)
            print(f"Created database {database_name}")
        else:
            print(f"Database {database_name} exist. Hence it will be overwritten.")
    except Exception as e:
        print(f"An error occurred while creating database: {e}")
        raise Exception(e)


def is_args_valid(args):
    is_args_valid = True
    for arg in vars(args):
        arg_value = getattr(args, arg)
        if arg_value == "":
            print(f"{arg} cannot be empty")
            is_args_valid = False
            break

    return is_args_valid


def check_if_database_exist(db_handle, database_name):
    cursor = db_handle.cursor()
    cursor.execute(DATABASE_EXISTENCE_QUERY.replace("database_name", database_name))

    if cursor.fetchone():
        is_database_exist = True
    else:
        is_database_exist = False

    cursor.close()

    return is_database_exist



def create_database(db_handle, database_name):
    cursor = db_handle.cursor()
    cursor.execute(CREATE_DATABASE_QUERY.replace("database_name", database_name))
    cursor.close()

