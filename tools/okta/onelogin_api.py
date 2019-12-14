import json
import collections
import requests
import urllib


class onelogin_api:
    base_url = ""
    username = ""
    password = ""

    headers = ""
    cookies = ""

    def __init__(self, base_url, username, password):
        self.base_url = base_url
        self.username = username
        self.password = password
        self.authenticate()

    def authenticate(self):
        url = f"{self.base_url}/authenticate/login"

        payload = {}
        payload["username"] = self.username
        payload["password"] = self.password

        headers = {"Content-Type": "application/json"}

        response = requests.post(
            url=url, data=json.dumps(payload), headers=headers, verify=True
        )

        if not response.ok:
            print(response)
            return None

        self.headers = {"Authorization": f"Bearer {response.json()['access_token']}"}
        self.cookies = dict(response.cookies)

        return response

    def get_site(self, application_id, environment_id, client_id):
        url = f"{self.base_url}/sites?application={application_id}&environment={environment_id}&member={client_id}"

        response = requests.get(
            url=url, headers=self.headers, cookies=self.cookies, verify=True
        )

        return response

    def get_client(self, client_name):
        url = f"{self.base_url}/members/{client_name}"

        response = requests.get(
            url=url, headers=self.headers, cookies=self.cookies, verify=True
        )

        return response
