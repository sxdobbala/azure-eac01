import pytest  # pylint: disable=import-error
import json
import logging
import sys
from opa.api import (
    opa_client_onboarding,
    opa_data_load,
    opa_post_data_load,
    opa_mstr_backup,
    opa_mstr_migration,
)

import opa.api

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


config = {
    "client_name": "CI client",
    "client_has_egr": "Y",
    "client_has_cubes": "N",
    "client_reporting_db": "dev",
    "instance_id": "i-033dc99b6b35c49e0",
    "env_id": "env-123456",
    "redshift/id": "opadevredshift-1-redshift-cluster",
    "redshift/host": "opadevredshift-1-redshift-cluster.cyf2jhkfukab.us-east-1.redshift.amazonaws.com",
    "redshift/port": 5439,
    "redshift/database": "dev",
    "redshift/username": "opa_admin",
    "redshift/client_database": "hCI",
    "redshift/client_username": "hCI_user",
    "cube_builder/username": "'HCI_Cube Builder'",
    # TODO: needs more refactoring
    "mstr_migration/folder_name": "/opt/mstr/MicroStrategy/Migration/release-9.0/mstr",
    "mstr_migration/release_name": "release-9.0",
    # TODO: replace with os.environ passed in through Terraform
    "data_load/data_bucket": "awsaccount-opa-client-data",
    "data_load/iam_role": "aws:iam:...",
    "mstr_backup/bucket_name": "awsaccount-opa-artifacts",
    # TODO: replace with constants
    "post_data_load/script_name": "/home/mstr/scripts/post_data_load_invoker.sh",
    "data_load/script_name": "/home/mstr/redshift/dataload_invoker.sh",
    "mstr_backup/script_name": "/home/mstr/scripts/mstr_backup_invoker.sh",
    "client_onboarding/script_name": "/home/mstr/scripts/create_new_client_invoker.sh",
    "mstr_migration/script_name": "/home/mstr/scripts/migrate_mstr_objects_invoker.sh",
    "data_load/ddl_base_path": "/home/mstr/redshift/OPADDL",
    "mstr_migration/migration_file": "/opt/mstr/MicroStrategy/Migration/migration_file.yaml",
}


# def test_client_opa_onboarding():
#     args = opa_client_onboarding.run_script_args("HCI", config)
#     assert args[0] == config["instance_id"]
#     assert args[1] == "python3"

#     cli_args = args[3]
#     assert "--mstr_password_key /env-123456/MSTR_PASSWORD" in cli_args


# def test_opa_data_load():
#     args = opa_data_load.run_script_args(config, "s3_prefix", "monthly")
#     assert args[0] == config["instance_id"]
#     assert args[1] == "python3"


# def test_post_opa_data_load():
#     args = opa_post_data_load.run_script_args("HCI", config, "monthly")
#     assert args[0] == config["instance_id"]
#     assert args[1] == "python3"

#     cli_args = args[3]
#     assert "--mstr_password_key /env-123456/MSTR_PASSWORD" in cli_args
#     assert (
#         "--cube_builder_password_key env-123456.HCI.cube-builder-password" in cli_args
#     )


# def test_opa_mstr_backup():
#     s3_bucket_name = config["mstr_backup/bucket_name"]
#     s3_key_name = "test_bucket_key"
#     args = opa_mstr_backup.run_script_args("test_client_id", config, s3_bucket_name, s3_key_name)
#     assert args[0] == config["instance_id"]
#     assert args[1] == "python3"

#     cli_args = args[3]
#     assert "--mstr_password_key /env-123456/MSTR_PASSWORD" in cli_args
#     assert "--mysql_password_key /env-123456/MSTR_PASSWORD" in cli_args
#     assert f"--s3_bucket_name {s3_bucket_name}" in cli_args
#     assert f"--s3_key_name {s3_key_name}" in cli_args


# def test_opa_mstr_migration():
#     # Validates current DEV D01 environment instance and script args
#     # TODO: reevaluate this test if we turn on stack rotation and we will destroy environments periodically
#     env_id = "env-164062"
#     migration_script = "test_migration_script"
#     migration_folder = "test_migration_folder"
#     migration_filename = "test_migration_filename"
#     release_id = "test_release_id"
#     args = opa_mstr_migration.run_script_args(env_id, migration_script, migration_folder, migration_filename, release_id)
#     assert args[0] == "i-033dc99b6b35c49e0"
#     assert args[1] == "python3"

#     cli_args = args[3]

#     assert "--mstr_password_key /env-164062/MSTR_PASSWORD" in cli_args
#     assert f"--folder_name {migration_folder}" in cli_args
#     assert f"--migration_file {migration_filename}" in cli_args
#     assert "--migration_strategy delta" in cli_args
#     assert f"--release_name {release_id}" in cli_args
