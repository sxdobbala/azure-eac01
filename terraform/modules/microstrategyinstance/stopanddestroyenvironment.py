#!/usr/bin/env python3

import urllib
import json
import boto3
import argparse
import sys
import time

client = boto3.client("ssm")
s3 = boto3.resource("s3")
parser = argparse.ArgumentParser(description="Destroy Environment")
parser.add_argument("--terraformId", help="EnvironmentID", required=True)
args = parser.parse_args()
terraformId = args.terraformId
envidresponse = client.get_parameter(
    Name=f"tf-{terraformId}.mstr.envid", WithDecryption=True
)

environmentid = envidresponse["Parameter"]["Value"]
print(environmentid)
environments = [environmentid]
url = "https://developer.customer.cloud.microstrategy.com/api/environments/stop"
mykey = client.get_parameter(Name="mstrapikey", WithDecryption=True)
req = urllib.request.Request(
    url,
    json.dumps(environments).encode("utf-8"),
    {"Content-Type": "application/json", "x-api-key": mykey["Parameter"]["Value"]},
)
f = urllib.request.urlopen(req)
response = f.read().decode("utf-8")
print(response)
f.close()


responsejson = json.loads(response)
if responsejson["success"] or responsejson["error"][0]["errorCode"] == 227:
    while True:
        print("wait for ability to terminate")
        url = "https://developer.customer.cloud.microstrategy.com/api/environments/terminate"
        req = urllib.request.Request(
            url,
            json.dumps(environments).encode("utf-8"),
            {
                "Content-Type": "application/json",
                "x-api-key": mykey["Parameter"]["Value"],
            },
        )
        f = urllib.request.urlopen(req)
        response = f.read().decode("utf-8")
        print(response)
        f.close()
        responsejson = json.loads(response)
        if responsejson["success"]:
            sys.exit(0)
        time.sleep(10)
else:
    sys.exit(1)
