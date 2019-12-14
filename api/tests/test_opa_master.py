import pytest  # pylint: disable=import-error
import json
import logging
from opa.api import opa_master

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


test_put = """
{
    "httpMethod": "PUT",
    "queryStringParameters": {},
    "body": {
        "clientId": "CI",
        "data": {
            "client_name": "CI client",
            "client_has_egr": "Y",
            "client_has_cubes": "N",
            "client_reporting_db": "dev",
            "instance_id": "i-033dc99b6b35c49e0",
            "env_id": "env-164062",
            "mstr/instance_id_0": "test_mstr_instance_1",
            "mstr/instance_id_1": "test_mstr_instance_1",
            "mstr/mstr_project_name": "mstr_project_name",
            "mstr/mstr_username": "mstr_username",
            "mstr/mstr_password_key": "mstr_password_key",
            "mstr/mysql_host": "mysql_host",
            "mstr/mysql_port": "mysql_port",
            "mstr/mysql_metadata_database": "mysql_metadata_database",
            "mstr/mysql_username": "mysql_username",
            "mstr/mysql_password_key": "mysql_password_key",
            "redshift/id": "opadevredshift-1-redshift-cluster",
            "redshift/host": "opadevredshift-1-redshift-cluster.clxtymtfekvn.us-east-1.redshift.amazonaws.com",
            "redshift/database": "dev",
            "redshift/port": "5439",
            "redshift/username": "test",
            "redshift/egress_sg_id": "egress_sg_id",
            "redshift/client_database": "ci_db",
            "redshift/client_username": "ci_user",
            "redshift/client_password_key": "opadevredshift-1-redshift-cluster.Hyyyyy.password",
            "data_load/instance_id": "i-033dc99b6b35c49e0",
            "data_load/script_runtime": "python3",
            "data_load/script_name": "/home/ssm-user/test_opa_data_load.py",
            "data_load/data_bucket": "data_bucket",
            "data_load/parquet_file_prefix": "parquet_file_prefix",
            "data_load/iam_role": "iam_role",
            "data_load/ddl_base_path": "ddl_base_path",
            "data_load/type": "monthly",
            "mstr_backup/instance_id": "i-033dc99b6b35c49e0",
            "mstr_backup/script_runtime": "python3",
            "mstr_backup/script_name": "/home/ssm-user/test_opa_mstr_backup.py",
            "mstr_backup/bucket_name": "mstr_backup_bucket",
            "mstr_metadata/instance_id": "i-033dc99b6b35c49e0",
            "mstr_metadata/script_runtime": "python3",
            "mstr_metadata/script_name": "/home/ssm-user/test_opa_mstr_metadata.py",
            "mstr_metadata/opa_username": "opa_username",
            "mstr_metadata/opa_password_key": "opa_password_key",
            "mstr_metadata/metadata_s3_uri": "metadata_s3_uri",
            "client_onboarding/instance_id": "i-033dc99b6b35c49e0",
            "client_onboarding/script_runtime": "python3",
            "client_onboarding/script_name": "/home/ssm-user/test_opa_client_onboarding.py",
            "post_data_load/instance_id": "i-033dc99b6b35c49e0",
            "post_data_load/script_runtime": "python3",
            "post_data_load/script_name": "/home/ssm-user/test_opa_post_data_load.py",
            "cube_builder/username": "cube_builder_username",
            "cube_builder/password_key": "cube_builder_password_key",
            "cube_builder/refresh_flag": "true",
            "mstr_migration/instance_id": "i-033dc99b6b35c49e0",
            "mstr_migration/script_runtime": "python3",
            "mstr_migration/script_name": "/home/ssm-user/test_opa_mstr_migration.py",
            "mstr_migration/folder_name": "/some/folder/name",
            "mstr_migration/migration_file": "some_migration_filename",
            "mstr_migration/migration_strategy": "full",
            "mstr_migration/release_name": "RC1",
            "dummy_key": "dummy_value",
            "opa_release": "9.0"
        }
    }
}
"""


test_get_one = """
{
  "httpMethod": "GET",
  "queryStringParameters": {
    "clientId": "CI",
    "configKey": "dummy_key"
  },
  "body": {}
}
"""


test_get_all = """
{
  "httpMethod": "GET",
  "queryStringParameters": {
    "clientId": "CI"
  },
  "body": {}
}
"""

test_delete = """
{
  "httpMethod": "DELETE",
  "queryStringParameters": {},
  "body": {
    "clientId": "CI",
    "configKey": "dummy_key"
  }
}
"""


test_bad_request = """
{
  "httpMethod": "GET",
  "queryStringParameters": {
    "missingClientId": ""
  },
  "body": {}
}
"""


@pytest.fixture(scope="package")
def opa_master_setup():
    """ Setup OPA Master database with configuration values for all tests """

    event = json.loads(test_put)
    response = opa_master.lambda_handler(event, None)
    return response


def test_opa_master_put(opa_master_setup):
    """ OPA Master lambda should save config values for a client """

    response = opa_master_setup
    logger.debug(response)
    assert response["statusCode"] == "200"


def test_opa_master_get_one():
    """ OPA Master lambda should return a single config value for a client """

    event = json.loads(test_get_one)
    response = opa_master.lambda_handler(event, None)
    logger.debug(response)
    assert response["statusCode"] == "200"
    assert response["body"] == '{"dummy_key": "dummy_value"}'


def test_opa_master_get_all():
    """ OPA Master lambda should return all config values for a client """

    event = json.loads(test_get_all)
    response = opa_master.lambda_handler(event, None)
    logger.debug(response)
    assert response["statusCode"] == "200"


def test_opa_master_get_delete():
    """ OPA Master lambda should delete a config value for a client """

    event = json.loads(test_delete)
    response = opa_master.lambda_handler(event, None)
    logger.debug(response)
    assert response["statusCode"] == "200"

    event = json.loads(test_get_one)
    response = opa_master.lambda_handler(event, None)
    logger.debug(response)
    assert response["statusCode"] == "404"


def test_opa_master_bad_request():
    """ OPA Master lambda should return http bad request for missing client id """

    event = json.loads(test_bad_request)
    response = opa_master.lambda_handler(event, None)
    logger.debug(response)
    assert response["statusCode"] == "400"
