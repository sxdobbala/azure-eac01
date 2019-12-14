import os

from tests import *

os.environ["ENV_PREFIX"] = "ci"
os.environ["AWS_REGION"] = "us-east-1"
os.environ["OPA_MASTER_LAMBDA"] = "dev-opa-opa-master"
os.environ[
    "OPA_MASTER_HOST"
] = "dev-opa-master-rds.c7b5ndug34sc.us-east-1.rds.amazonaws.com"
os.environ["OPA_MASTER_PORT"] = "5432"
os.environ["OPA_MASTER_DATABASE"] = "opa_master"
os.environ["OPA_MASTER_USER"] = "opa_admin"
os.environ["OPA_MASTER_PASSWORD_KEY"] = "/dev/dev-opa-master.master-password"
os.environ["OPA_RELEASE_SNS_ROLE_ARN"] = ""
os.environ["OPA_RELEASE_SNS_TOPIC_ARN"] = ""
os.environ["ARTIFACTS_BUCKET"] = "760182235631-opa-artifacts-opa"
os.environ["MSTR_BACKUPS_BUCKET"] = "760182235631-opa-mstr-backups"
os.environ["TF_BACKEND_BUCKET"] = ""
os.environ["TF_BACKEND_TABLE"] = ""
os.environ["SCRIPT_RUNTIME"] = "python3"
