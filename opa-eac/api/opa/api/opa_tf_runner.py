import os
import subprocess
import boto3
import json
import logging
import re
import glob
import tempfile

from datetime import datetime
from zipfile import ZipFile
from opa.api import vars, helpers
from opa.utils import exceptions, http, ssm

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

TERRAFORM_VERSION = "0.11.14"
TERRAFORM_S3_BUCKET = vars.ARTIFACTS_BUCKET
TERRAFORM_S3_KEY = f"terraform/terraform_{TERRAFORM_VERSION}_linux_amd64.zip"

# Most of a Lambda's disk is read-only, but some transient storage is
# provided in /tmp, so we'll use it for all operations.
# This storage may persist between invocations, so we'll need to:
# - skip download of terraform executable if it's already there
# - clean existing *.tf and *.tfvars files from prior runs
TERRAFORM_DIR = "/tmp"
# archive with terraform executable
TERRAFORM_EXE_ARCHIVE = "/tmp/terraform.zip"
# path to terraform executable
TERRAFORM_EXE = "/tmp/terraform"
# zip with tf files we'll be applying with terraform
TERRAFORM_PROJECT = "/tmp/project.zip"
# name of plan file we'll be applying with terraform
TERRAFORM_PLAN = "/tmp/terraform.tfplan"
# vars file to use when applying with terraform
TERRAFORM_VARS = "/tmp/terraform.tfvars"
# file for backend setup
TERRAFORM_BACKEND = "/tmp/backend.tf"


def lambda_handler(event, context):
    http.log_input(logger, event, context)

    try:
        operation = event["httpMethod"]

        # get terraform-related input settings
        tf_source_bucket = http.get_request_parameter(event, "tf_source_bucket")
        tf_source_key = http.get_request_parameter(event, "tf_source_key")
        tf_vars = http.get_request_parameter(event, "tf_vars")

        # get env_id if present in the tf_vars, making sure to strip out quotes
        env_id = helpers.clean_text(tf_vars.get("env_id"))

        # either get tf_backend_key if passed in, or construct it from the env_id
        tf_backend_key = get_tf_backend_key(event, env_id)

        # TODO: when this is called from a step function we want to use simple JSON, without an http wrapper
        # think about refactoring this in future iterations
        from_step_function = (
            http.get_request_parameter(event, "executionId", required=False) != ""
        )

        if operation == "POST":
            process_operation(
                tf_source_bucket,
                tf_source_key,
                tf_vars,
                tf_backend_key,
                "apply",
                env_id,
            )

            result = {}

            if from_step_function:
                return result
            else:
                return http.success(json.dumps(result))

        elif operation == "DELETE":
            process_operation(
                tf_source_bucket,
                tf_source_key,
                tf_vars,
                tf_backend_key,
                "destroy",
                env_id,
            )

            result = {}

            if from_step_function:
                return result
            else:
                return http.success(json.dumps(result))

    except exceptions.ApiMissingRequestParameter as error:
        logger.exception(error)

        if from_step_function:
            raise
        else:
            return http.bad_request(str(error))

    except Exception as error:
        logger.exception(error)

        if from_step_function:
            raise
        else:
            return http.internal_server_error()


def process_operation(
    tf_source_bucket, tf_source_key, tf_vars, tf_backend_key, operation, env_id
):
    logger.info("Cleaning working directory...")
    clean_directory()

    logger.info("Installing terraform...")
    install_terraform()

    logger.info("Creating backend.tf...")
    create_backend_tf(tf_backend_key)

    logger.info("Creating terraform.tfvars...")
    create_terraform_tfvars(tf_vars)

    logger.info("Running terraform...")
    run_terraform(operation, tf_source_bucket, tf_source_key)

    logger.info("Archiving bundle that was executed...")
    archive_bundle(tf_source_bucket, tf_source_key, env_id)


def get_tf_backend_key(event, env_id):
    tf_backend_key = http.get_request_parameter(event, "tf_backend_key", required=False)

    if not tf_backend_key:
        if env_id:
            tf_backend_key = f"{env_id}/terraform.state"
        else:
            raise exceptions.ApiMissingRequestParameter(
                "Missing tf_vars['env_id'] parameter. It is required when 'tf_backend_key' is not explicitly passed in."
            )

    return tf_backend_key


def clean_directory():
    # delete all files in /tmp
    check_call(["ls", "-al"])

    try:
        check_call(["rm", "-rfv", "/tmp/*"])
        check_call(["rm", "-r", "/tmp/.terraform"])
    except:
        # ignore delete errors - files were likely not there
        return

    check_call(["ls", "-al"])


def install_terraform():
    download_from_s3(TERRAFORM_S3_BUCKET, TERRAFORM_S3_KEY, TERRAFORM_EXE_ARCHIVE)
    unzip_archive(TERRAFORM_EXE_ARCHIVE, TERRAFORM_DIR)

    check_call([TERRAFORM_EXE, "--version"])


def create_backend_tf(tf_backend_key):
    aws_region = os.environ["AWS_REGION"]

    with open(TERRAFORM_BACKEND, "w") as f:
        f.write("terraform {\n")
        f.write('  backend "s3" {\n')
        f.write(f'    bucket = "{vars.TF_BACKEND_BUCKET}"\n')
        f.write(f'    key = "{tf_backend_key}"\n')
        f.write(f'    dynamodb_table = "{vars.TF_BACKEND_TABLE}"\n')
        f.write(f'    encrypt = "true"\n')
        f.write(f'    region = "{aws_region}"\n')
        f.write("  }\n")
        f.write(f'  required_version = ">= {TERRAFORM_VERSION}"\n')
        f.write("}\n")

    check_call(["cat", TERRAFORM_BACKEND])


def create_terraform_tfvars(tf_vars):
    with open(TERRAFORM_VARS, "w") as f:
        for key in tf_vars:
            value = helpers.clean_text(tf_vars[key])
            f.write(f'{key} = "{value}"\n')

    check_call(["cat", TERRAFORM_VARS])


def run_terraform(operation, tf_source_bucket, tf_source_key):
    download_from_s3(tf_source_bucket, tf_source_key, TERRAFORM_PROJECT)
    unzip_archive(TERRAFORM_PROJECT, TERRAFORM_DIR)

    check_call([TERRAFORM_EXE, "init", "-input=false"])

    if operation == "apply":
        check_call([TERRAFORM_EXE, "plan", f"-out={TERRAFORM_PLAN}", "-input=false"])
        check_call([TERRAFORM_EXE, operation, "-auto-approve", TERRAFORM_PLAN])

    elif operation == "destroy":
        check_call([TERRAFORM_EXE, operation, "-auto-approve"])


def download_from_s3(s3_bucket, s3_key, destination_filename):
    s3 = boto3.client("s3")
    s3.download_file(s3_bucket, s3_key, destination_filename)


def decode_log(stream):
    # convert to utf-8
    return stream.decode("utf-8")


def check_call(args):
    proc = subprocess.Popen(
        args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=TERRAFORM_DIR
    )

    b_stdout, b_stderr = proc.communicate()
    stdout = decode_log(b_stdout)
    stderr = decode_log(b_stderr)

    logger.info(stdout)

    # log any errors and raise exception
    if proc.returncode != 0:
        logger.error(stderr)
        raise subprocess.CalledProcessError(returncode=proc.returncode, cmd=args)


def unzip_archive(zipfile, destination_folder):
    # Unzip and overwrite without asking (-o)
    check_call(["unzip", "-o", zipfile, "-d", destination_folder])


def archive_bundle(tf_source_bucket, tf_source_key, env_id):
    # Destination key in s3 will be using format f"archives/{zip_file}.{env_id}.{timestamp}.zip"
    zip_file = tf_source_key.split("/")[-1]
    prefix_index = tf_source_key.rfind(zip_file)
    tf_source_key_prefix = tf_source_key[:prefix_index]
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    tf_dest_key = f"{tf_source_key_prefix}archives/{zip_file}.{env_id}.{timestamp}.zip"
    logger.info(f"Bundle will be saved in s3 with key: {tf_dest_key}")

    # Upload archive to s3
    logger.info("Creating archive with all '*.tf*' files...")
    os.chdir(TERRAFORM_DIR)
    tf_files = glob.glob("*.tf*")
    with tempfile.NamedTemporaryFile() as temp:
        with ZipFile(temp, "w") as zip:
            for file in tf_files:
                zip.write(file)
        s3 = boto3.client("s3")
        s3.upload_file(temp.name, tf_source_bucket, tf_dest_key)
