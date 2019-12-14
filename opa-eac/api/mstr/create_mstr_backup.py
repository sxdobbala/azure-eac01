#!/usr/bin/env python3
import os
import sys
import argparse
import subprocess
import json
import socket
import re
import boto3
import mstr_utility

# Getting configs
with open(os.path.join(sys.path[0], "general_config.json"), "r") as f:
    generalconfig = json.load(f)


def update_config(details):
    """ create backup response file with environment specific values """
    with open(os.path.join(sys.path[0], "backup_response_template.json"), "r") as f:
        response_config = json.load(f)

    response_config["mstrbak"]["backup_path"] = details["BakFileLocation"]
    response_config["mstr"]["username"] = details["MSTRUser"]
    response_config["mstr"]["password"] = details["MSTRPwd"]
    response_config["dsns"]["metadata"]["username"] = details["MySQLUser"]
    response_config["dsns"]["metadata"]["password"] = details["MySQLPwd"]
    response_config["mstr"]["project_source_name"] = details["ProjectSourceName"]
    response_config["mstr"]["server_definition"] = details["ServerDef"]
    response_config["mstr"]["hostnames"] = details["HostNames"]
    response_config["mstr"]["mstr_version"] = details["MstrVersion"]

    with open("/tmp/backup_mstr_response.json", "w") as f:
        json.dump(response_config, f, ensure_ascii=False, indent=2)


# Backup MSTR Project
def run_mstrbackuptool_command(dump_mode):
    """ Execute mstrbak tool to create mstr environment artifact """

    dump_mode_arg = "-d" if args.dump_mode else ""

    mstr_bak_output = subprocess.check_output(
        f"sudo TMPDIR={generalconfig['mstrbak_path']} ./mstrbak {dump_mode_arg} -r /tmp/backup_mstr_response.json",
        shell=True,
        stderr=subprocess.STDOUT,
        cwd=generalconfig["mstrbak_path"],
    )

    return mstr_bak_output.decode("utf-8")


# Upload to S3
def upload_artifact_to_s3(filename, bucket, key):
    """ Upload the generated mstr backup to S3 """
    s3 = boto3.client("s3")
    s3.upload_file(filename, bucket, key)


# MainProject
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Input for MSTR Environment Backup")
    parser.add_argument("--mstr-username", help="MicroStrategy UserName", required="true", type=str)
    parser.add_argument("--mstr-password-key", help="MicroStrategy Password", required="true", type=str)
    parser.add_argument("--mysql-username", help="Mysql UserName", required="true", type=str)
    parser.add_argument("--mysql-password-key", help="Mysql Password", required="true", type=str)
    parser.add_argument(
        "--s3-bucket-name", help="S3 bucket where the backup will be uploaded", required="true", type=str,
    )
    parser.add_argument(
        "--s3-key-name", help="S3 key where the backup will be uploaded", required="true", type=str,
    )
    parser.add_argument(
        "--dump-mode", help="Specifies whether mstrbak should use dump mode; does not allow for upgrade", action="store_true"
    )

    args = parser.parse_args()
    host_name = socket.gethostname()
    projectsource_template_ini = generalconfig["projectsource_template_ini"]
    mstr_utility.add_projectsource(projectsource_template_ini, host_name)
    mstr_home_path = generalconfig["mstr_home_path"]

    # Get Server definition
    server_definition = (
        subprocess.check_output(f"grep ServerInstanceName {mstr_home_path}MSIReg.reg", shell=True).decode("utf-8").strip()
    )

    mstr_version = subprocess.check_output(f"grep -w Version {mstr_home_path}MSIReg.reg", shell=True).decode("utf-8").strip()

    params = {
        "BakFileLocation": generalconfig["artifact_path"],
        "MSTRUser": args.mstr_username,
        "MSTRPwd": mstr_utility.get_parameter(args.mstr_password_key),
        "MySQLUser": args.mysql_username,
        "MySQLPwd": mstr_utility.get_parameter(args.mysql_password_key),
        "ProjectSourceName": host_name,
        "ServerDef": re.split("=", server_definition.replace('"', ""))[1],
        "HostNames": mstr_utility.list_all_servers_in_cluster(
            host_name, args.mstr_username, mstr_utility.get_parameter(args.mstr_password_key),
        ),
        "MstrVersion": re.split("=", mstr_version.replace('"', ""))[1],
    }

    # Updating Template file to generate response file.
    update_config(params)

    # Run MSTRBak tool
    mstr_bak_output = run_mstrbackuptool_command(args.dump_mode)

    # Writing backup tool response to the file for logging purpose.
    with open("backup_output.txt", "at") as f:
        f.write(mstr_bak_output)

    # Getting Artifact path for uploading file to S3
    artifact_path = re.search(r"archive created locally at:(.*.tar.gz)", mstr_bak_output).group(1)

    upload_artifact_to_s3(artifact_path.strip(), args.s3_bucket_name, args.s3_key_name)

    print(f"Artifact Successfully generated and uploaded to s3://{args.s3_bucket_name}/{args.s3_key_name}")

    os.remove("/tmp/backup_mstr_response.json")
