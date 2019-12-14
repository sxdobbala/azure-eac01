#!/usr/bin/env python3
import os
import collections
import csv
import socket
import boto3
import argparse
import datetime
import subprocess
from mstr_api import mstr_api

WEBAPPS_PATH = "/opt/apache/tomcat/latest/webapps"
COMMAND_MANAGER_PATH = "/opt/mstr/MicroStrategy/bin/mstrcmdmgr"
MSTR_TOKEN_PATH = "/opt/apache/tomcat/latest/MicroStrategy/WEB-INF/xml"
MSTR_API_URL = "http://localhost:8080/MicroStrategyLibrary/api"


def read_trust_token():
    MSTR_LIBRARY_PROPERTIES_FILE = f"{WEBAPPS_PATH}/MicroStrategyLibrary/WEB-INF/classes/config/configOverride.properties"
    MSTR_TRUST_KEY = "iserver.trustToken"

    properties = {}

    with open(MSTR_LIBRARY_PROPERTIES_FILE) as f:
        for line in f:
            if line.strip() == "" or line.startswith("#"):
                continue

            k, v = line.partition("=")[::2]
            properties[k.strip()] = v.strip()

    if MSTR_TRUST_KEY in properties:
        return properties[MSTR_TRUST_KEY]
    else:
        raise Exception(
            f"MSTR {MSTR_TRUST_KEY} not found in {MSTR_LIBRARY_PROPERTIES_FILE}"
        )


def get_token_filenames(iserver_names):
    filenames = []

    for server_name in iserver_names:
        filenames.append(f"{MSTR_TOKEN_PATH}/{server_name.upper()}.token")
        filenames.append(f"{MSTR_TOKEN_PATH}/{server_name.lower()}.token")

    return filenames


def create_token_files(filenames, trust_token):
    encoding = 'utf-16'
    encoded_trust_token = trust_token.strip().encode(encoding)

    for filename in filenames:
        with open(filename, "w", encoding=encoding) as f:
            f.write(str(encoded_trust_token, encoding))


def establish_trust(
    api_url, mstr_username, mstr_password, tomcat_username, tomcat_password, app_path
):
    mstr = mstr_api(api_url, mstr_username, mstr_password)

    print("Making test call to get projects...")
    projects = mstr.get_projects()
    print(projects)
    print(projects.content)

    if not projects.ok:
        raise Exception(f"Cannot get list of projects: {projects.content}")

    print("Finding out if trust is enabled...")
    trust = mstr.get_mstr_trust(tomcat_username, tomcat_password)
    print(trust)
    print(trust.content)

    if not trust.ok:
        raise Exception(
            f"Cannot get trust relationship status: {trust.content}")

    print("Setting up trust relationship...")
    trust = mstr.set_mstr_trust(tomcat_username, tomcat_password, app_path)
    print(trust)
    print(trust.content)
    print(trust.headers)


def get_ssm_parameter(key, decrypt=True):
    ssm = boto3.client("ssm")
    try:
        ssm_response = ssm.get_parameter(Name=key, WithDecryption=decrypt)
        return ssm_response["Parameter"]["Value"]
    except ssm.exceptions.ParameterNotFound:
        return None


def put_ssm_parameter(key, value, type="SecureString", overwrite=True):
    ssm = boto3.client("ssm")
    ssm.put_parameter(Name=key, Value=value, Type=type, Overwrite=overwrite)


if __name__ == "__main__":
    mstr_host = socket.gethostname()
    print(f"MSTR hostname = {mstr_host}")

    mstr_password_key = f"/{mstr_host.split('l')[0]}/MSTR_PASSWORD"
    print(f"MSTR password key = {mstr_password_key}")

    parser = argparse.ArgumentParser(
        description="Required parameters to establish MSTR trust relationship on the local machine"
    )
    parser.add_argument(
        "--mstr_username", type=str, help="MicroStrategy username", default="mstr"
    )
    parser.add_argument(
        "--mstr_password_key",
        type=str,
        help="SSM key name for MicroStrategy password",
        default=mstr_password_key,
    )
    parser.add_argument(
        "--mstr_trust_token_key",
        type=str,
        help="SSM key name for MicroStrategy trust token",
        required="true",
    )
    parser.add_argument(
        "--webapp_path",
        type=str,
        help="MSTR web application path to establish trust with",
        required="true",
    )
    parser.add_argument(
        "--iserver_names",
        type=str,
        help="Comma-delimited list of MSTR i-server names in the cluster",
        required="true",
    )
    args = parser.parse_args()

    mstr_username = args.mstr_username
    mstr_password = get_ssm_parameter(args.mstr_password_key)
    mstr_trust_token_key = args.mstr_trust_token_key
    webapp_path = args.webapp_path

    # first try to get token from SSM
    token = get_ssm_parameter(mstr_trust_token_key)

    # if token is not in SSM, get it via MSTR API and save it to SSM
    if token is None:
        establish_trust(
            MSTR_API_URL,
            mstr_username,
            mstr_password,
            mstr_username,
            mstr_password,
            webapp_path,
        )
        token = read_trust_token()
        print(f"Trust token = {token}")
        put_ssm_parameter(mstr_trust_token_key, token)

    filenames = get_token_filenames(args.iserver_names.split(","))
    print(f"Token filenames = {filenames}")

    create_token_files(filenames, token)
    print("Token files created")
