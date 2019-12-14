import json
import collections
import requests

MSTR_API_URL = "http://localhost:8080/MicroStrategyLibrary/api"


class mstr_api:
    base_url = ""
    username = ""
    password = ""

    auth_token = ""
    cookies = ""
    project_id = ""

    def __init__(self, base_url, username, password):
        self.base_url = base_url
        self.username = username
        self.password = password
        self.authenticate()

    def authenticate(self):
        url = f"{self.base_url}/auth/login"

        payload = {}
        payload["loginMode"] = 1
        payload["username"] = self.username
        payload["password"] = self.password

        headers = {"Content-Type": "application/json"}

        response = requests.post(
            url=url, data=json.dumps(payload), headers=headers, verify=True
        )

        self.auth_token = response.headers.get("X-MSTR-AuthToken")
        self.cookies = dict(response.cookies)

        return response

    def get_projects(self):
        url = f"{self.base_url}/projects"

        response = requests.get(
            url=url,
            headers={"X-MSTR-AuthToken": self.auth_token},
            cookies=self.cookies,
            verify=True,
        )

        return response

    def get_mstr_trust(self, tomcat_username, tomcat_password):
        # MSTR needs to re-auth before calls to /admin/ endpoint
        self.authenticate()

        url = f"{self.base_url}/admin/restServerSettings/iServer/trustRelationship"

        headers = {
            "X-MSTR-AuthToken": self.auth_token,
            "Content-Type": "application/json",
        }

        response = requests.get(
            url=url,
            headers=headers,
            cookies=self.cookies,
            auth=(tomcat_username, tomcat_password),
        )

        return response

    def set_mstr_trust(self, tomcat_username, tomcat_password, path):
        # MSTR needs to re-auth before calls to /admin/ endpoint
        self.authenticate()

        url = f"{self.base_url}/admin/restServerSettings/iServer/trustRelationship"

        payload = {}
        payload["webServerPath"] = path

        headers = {
            "X-MSTR-AuthToken": self.auth_token,
            "Content-Type": "application/json",
        }

        response = requests.post(
            url=url,
            data=json.dumps(payload),
            headers=headers,
            cookies=self.cookies,
            auth=(tomcat_username, tomcat_password),
        )

        return response
