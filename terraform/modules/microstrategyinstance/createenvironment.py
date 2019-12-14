#!/usr/bin/env python3

import urllib
import json
import boto3
import os
import argparse


client = boto3.client("ssm")
parser = argparse.ArgumentParser(description="Create Environments")
parser.add_argument("--terraformId", help="EnvironmentID", required=True)
args = parser.parse_args()

data = {}
data["environmentName"] = os.environ["environmentName"]
data["environmentType"] = os.environ["environmentType"]

data["region"] = "us-east-1"
data["microStrategyVersion"] = os.environ["microStrategyVersion"]
data["contactInformation"] = {}
data["contactInformation"]["firstName"] = os.environ["firstName"]
data["contactInformation"]["lastName"] = os.environ["lastName"]
data["contactInformation"]["email"] = os.environ["email"]
data["contactInformation"]["company"] = os.environ["company"]
data["instanceInformation"] = {}
data["instanceInformation"]["developerInstanceType"] = os.environ[
    "developerInstanceType"
]
data["instanceInformation"]["platformInstanceType"] = os.environ["platformInstanceType"]
data["instanceInformation"]["platformOS"] = os.environ["platformOS"]
data["instanceInformation"]["rdsInstanceType"] = os.environ["rdsInstanceType"]
data["instanceInformation"]["rdsSize"] = os.environ["rdsSize"]

data["awsAccount"] = os.environ["awsAccount"]
data["mstrBakS3BucketLocation"] = os.environ["mstrbak"]
data["enterpriseApplication"] = "Tutorial"
url = "https://developer.customer.cloud.microstrategy.com/api/environments"
mykey = os.environ["apikey"]
encodeddata = json.dumps(data).encode("utf-8")
# print(encodeddata)
req = urllib.request.Request(
    url, encodeddata, {"Content-Type": "application/json", "x-api-key": mykey}
)

f = urllib.request.urlopen(req)
response = f.read()

f.close()

responsedecode = response.decode("utf-8")
print(responsedecode)
responsedata = json.loads(responsedecode)
terraformId = args.terraformId
print(
    client.put_parameter(
        Name=f"tf-{terraformId}.mstr.output",
        Value=responsedecode,
        Type="SecureString",
        Overwrite=True,
    )
)
environmentId = responsedata["data"]["environmentId"]
print(
    client.put_parameter(
        Name=f"tf-{terraformId}.mstr.envid",
        Value=str(environmentId),
        Type="SecureString",
        Overwrite=True,
    )
)
