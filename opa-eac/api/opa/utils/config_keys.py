# This file should be used to store key names of settings in OPA Master

CLIENT_NAME = "client_name"
CLIENT_HAS_EGR = "client_has_egr"
CLIENT_HAS_CUBES = "client_has_cubes"
ENV_ID = "env_id"
# TODO: get rid of REDSHIFT_ID_OLD when existing clients have been migrated to REDSHIFT_ID
REDSHIFT_ID = "redshift_id"
REDSHIFT_ID_OLD = "redshift/id"

# data_load
DATA_LOAD_SCRIPT_NAME = "data_load/script_name"
DATA_LOAD_COMMAND_ID = "data_load/command_id"
DATA_LOAD_DATA_BUCKET = "data_load/data_bucket"
DATA_LOAD_IAM_ROLE = "data_load/iam_role"
DATA_LOAD_DDL_BASE_PATH = "data_load/ddl_base_path"

# post_data_load
POST_DATA_LOAD_COMMAND_ID = "post_data_load/command_id"
