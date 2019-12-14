import os
from opa.utils import api

ENV_PREFIX = api.get_os_environ_value("ENV_PREFIX")
AWS_REGION = api.get_os_environ_value("AWS_REGION")
OPA_MASTER_LAMBDA = api.get_os_environ_value("OPA_MASTER_LAMBDA")
OPA_MASTER_HOST = api.get_os_environ_value("OPA_MASTER_HOST")
OPA_MASTER_PORT = api.get_os_environ_value("OPA_MASTER_PORT")
OPA_MASTER_DATABASE = api.get_os_environ_value("OPA_MASTER_DATABASE")
OPA_MASTER_USER = api.get_os_environ_value("OPA_MASTER_USER")
OPA_MASTER_PASSWORD_KEY = api.get_os_environ_value("OPA_MASTER_PASSWORD_KEY")
OPA_RELEASE_SNS_ROLE_ARN = api.get_os_environ_value("OPA_RELEASE_SNS_ROLE_ARN")
OPA_RELEASE_SNS_TOPIC_ARN = api.get_os_environ_value("OPA_RELEASE_SNS_TOPIC_ARN")
ARTIFACTS_BUCKET = api.get_os_environ_value("ARTIFACTS_BUCKET")
MSTR_BACKUPS_BUCKET = api.get_os_environ_value("MSTR_BACKUPS_BUCKET")
TF_BACKEND_BUCKET = api.get_os_environ_value("TF_BACKEND_BUCKET")
TF_BACKEND_TABLE = api.get_os_environ_value("TF_BACKEND_TABLE")
SCRIPT_PATH = api.get_os_environ_value("SCRIPT_PATH")
SCRIPT_PATH_MSTR = f"{SCRIPT_PATH.rstrip('/')}/mstr-infra/mstr/"
SCRIPT_PATH_DATA_LOAD = f"{SCRIPT_PATH.rstrip('/')}/opa-rep-loaders/"
SCRIPT_RUNTIME = api.get_os_environ_value("SCRIPT_RUNTIME", "sh")
