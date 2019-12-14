# This script can be run to fetch the Okta client secret(s) for a particular client and save them to SSM.
#
# Syntax:
#   python3 okta.py --env-prefix [dev|qa|stage|prod] -env-id [env-xxxxxx] -client-name ["Acme Hospital"]
#
# Notes:
#   - it is extremely difficult and sometimes impossible to get the correct client from OneLogin API because the API
#     filters very poorly - e.g. searching for "Lehigh" in PROD returns two results and one of them can never be found
#     by itself because it's a substring of the other. BOO YAH!!
#   - for the reason above, it's recommended to search for simple and somewhat *unique* strings - the script will allow you to
#     make an interactive selection of the correct client
#   - this script cannot be run from AWS since it requires hybrid connectivity to OneLogin
#   - this script will overwrite any existing sso_okta_secret or sso_esm_admin_password settings so don't run for existing clients
#   - prior to running the script ensure that SSM has the following settings configured:
#       - "onelogin-admin-username": "registryAdmin"
#       - "onelogin-admin-password": [valid admin password OneLogin or OneLoginBeta depending on nonprod/prod env]

import argparse
import logging
import sys
import boto3

from onelogin_api import onelogin_api

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

ONELOGIN_PROD_API_URL = "https://onelogin.advisory.com/api"
ONELOGIN_BETA_API_URL = "https://oneloginbeta.advisory.com/api"

ONELOGIN_ADMIN_USERNAME_KEY = "onelogin-admin-username"
ONELOGIN_ADMIN_PASSWORD_KEY = "onelogin-admin-password"

OPA_PROD_APPLICATION_ID = "a5c9e82e-6a00-44d0-afb4-6100889f6fe1"
OPA_BETA_APPLICATION_ID = "b49d0c56-2753-4365-8199-d9e49772ed34"

OPA_PROD_ENVIRONMENT_ID = "67d939bb-b3ef-4b52-bd47-a69af5351a7b"
OPA_STAGE_ENVIRONMENT_ID = "6127397f-410a-4e0e-bd68-fc4ba234d6a3"
OPA_QA_ENVIRONMENT_ID = "37b473ae-b5a5-4839-91d5-80676a86b4b9"
OPA_DEV_ENVIRONMENT_ID = "48871ccc-2e86-4e8d-bfa8-901227cec118"


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


def get_client_id(onelogin, client_name):
    response = onelogin.get_client(client_name)

    if not response.ok:
        raise Exception(
            f"onelogin.get_client('{client_name}') call failed: {response.text}"
        )

    clients = response.json()

    if not len(clients) == 1:
        print(f"Too many clients matched. Please select correct client below:\n")
        return choose_single_client(clients)
    else:
        return clients[0]["SIAMMemberKey"]


def choose_single_client(clients):
    count = len(clients)

    choices = []
    choices.append("[0] Exit without selection\n")

    for i in range(0, count):
        client = clients[i]
        choices.append(f"[{i+1}] (SIAM: {client['SIAMMemberKey']}) {client['Name']}\n")

    while True:
        choice = input("".join(choices))

        try:
            index = int(choice)

            if index == 0:
                sys.exit(0)

            client = clients[index - 1]
            print(f"Selected client... {choices[index]}")

            return client["SIAMMemberKey"]

        except Exception:
            print(f"Invalid choice. Please select a value from 0 to {count}")


def get_client_secret(onelogin, application_id, environment_id, client_id):
    response = onelogin.get_site(application_id, environment_id, client_id)

    if not response.ok:
        raise Exception(
            f"onelogin.get_site('{application_id}', '{environment_id}', '{client_id}') call failed:  {response.text}"
        )

    sites = response.json()["SiteDetails"]
    site_count = len(sites)

    if not site_count == 1:
        site_names = "\n".join([sites["Name"] for client in sites])
        raise Exception(
            f"Single site match expected. Too many sites returned: \n{site_names}"
        )

    # return Okta client secret
    return sites[0]["ClientSecret"]


def get_onelogin_url(env_prefix):
    switcher = {
        "prod": ONELOGIN_PROD_API_URL,
        "stage": ONELOGIN_PROD_API_URL,
        "qa": ONELOGIN_BETA_API_URL,
        "dev": ONELOGIN_BETA_API_URL,
    }

    # return url specific to env_prefix; assume beta url if no match found
    return switcher.get(env_prefix.lower(), ONELOGIN_BETA_API_URL)


def get_application_id(env_prefix):
    switcher = {
        "prod": OPA_PROD_APPLICATION_ID,
        "stage": OPA_PROD_APPLICATION_ID,
        "qa": OPA_BETA_APPLICATION_ID,
        "dev": OPA_BETA_APPLICATION_ID,
    }

    # return application id specific to env_prefix; assume beta application id if no match found
    return switcher.get(env_prefix.lower(), OPA_BETA_APPLICATION_ID)


def get_environment_id(env_prefix):
    switcher = {
        "prod": OPA_PROD_ENVIRONMENT_ID,
        "stage": OPA_STAGE_ENVIRONMENT_ID,
        "qa": OPA_QA_ENVIRONMENT_ID,
        "dev": OPA_DEV_ENVIRONMENT_ID,
    }

    # return environment id specific to env_prefix; assume dev environment id if no match found
    return switcher.get(env_prefix.lower(), OPA_DEV_ENVIRONMENT_ID)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Required parameters to fetch and save to SSM the Okta client secret"
    )
    parser.add_argument(
        "--env-prefix",
        type=str,
        help="Logical environment, e.g. dev, qa, prod, dev-momchil",
        required="true",
    )
    parser.add_argument(
        "--env-id", type=str, help="Environment ID, e.g. env-123456", required="true"
    )
    parser.add_argument(
        "--client-name",
        type=str,
        help="Full name of the client (must match SIAM entry)",
        required="true",
    )
    args = parser.parse_args()

    url = get_onelogin_url(args.env_prefix)
    username = get_ssm_parameter(ONELOGIN_ADMIN_USERNAME_KEY, False)
    password = get_ssm_parameter(ONELOGIN_ADMIN_PASSWORD_KEY)
    onelogin = onelogin_api(url, username, password)
    print(f"OneLogin api client created using url = {url}")

    # get OPA application id depending on the env_prefix
    onelogin_application_id = get_application_id(args.env_prefix)
    print(f"Using onelogin_application_id = {onelogin_application_id}")

    # get OPA environment id depending on the env_prefix
    onelogin_environment_id = get_environment_id(args.env_prefix)
    print(f"Using onelogin_environment_id = {onelogin_environment_id}")

    # first find the SIAM client id based on the client name
    siam_client_id = get_client_id(onelogin, args.client_name)
    print(f"Found siam_client_id = {siam_client_id}")

    # next get the Okta client secret
    client_secret = get_client_secret(
        onelogin, onelogin_application_id, onelogin_environment_id, siam_client_id
    )
    print("Client secret obtained.")

    # finally save the client secret to SSM for the given env_id
    put_ssm_parameter(f"/{args.env_id}/sso_okta_secret", client_secret)

    # also save the ESM admin password to SSM for the given env_id
    put_ssm_parameter(f"/{args.env_id}/sso_esm_admin_password", password)

    print("Done.")
