import urllib2
import json
import boto3
import argparse

parser = argparse.ArgumentParser(description="Terminate Environments")
parser.add_argument(
    "environments", metavar="N", type=int, nargs="+", help="List of Environments"
)
args = parser.parse_args()
client = boto3.client("ssm")

data = args.environments

url = "https://developer.customer.cloud.microstrategy.com/api/environments/terminate"
mykey = client.get_parameter(Name="mstrapikey", WithDecryption=True)
req = urllib2.Request(
    url,
    json.dumps(data),
    {"Content-Type": "application/json", "x-api-key": mykey["Parameter"]["Value"]},
)
f = urllib2.urlopen(req)
response = f.read()
print(response)
f.close()
