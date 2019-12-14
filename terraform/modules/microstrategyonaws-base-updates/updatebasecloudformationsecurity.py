#!/usr/bin/env python3

import json
import boto3
from botocore.exceptions import ClientError
from collections import OrderedDict
from operator import itemgetter
from sys import argv
import subprocess
import argparse

parser = argparse.ArgumentParser(description="Update Security for MSTR")
parser.add_argument("--ingresscidrblock", help="CIDR Block for Ingress", required=True)
parser.add_argument("--vpccidrblock", help="CIDR Block from VPC", required=True)
parser.add_argument("--s3bucket", help="S3 Bucket for Artifact", required=True)
parser.add_argument("--publicsubnet01", help="Public Subnet 1 ID", required=True)
parser.add_argument("--publicsubnet02", help="Public Subnet 2 ID", required=True)
parser.add_argument("--privatesubnet01", help="Private Subnet 1 ID", required=True)
parser.add_argument("--privatesubnet02", help="Private Subnet 2 ID", required=True)
parser.add_argument("--vpc", help="VPC ID", required=True)

args = parser.parse_args()

client = boto3.client("cloudformation")
ingresscidrblock = args.ingresscidrblock
s3Bucket = args.s3bucket
print(ingresscidrblock)
print(s3Bucket)

cftemplate = client.get_template(StackName="MicroStrategyOnAWS")["TemplateBody"]
ingressarray = cftemplate["Resources"]["AppELBSG"]["Properties"]["SecurityGroupIngress"]
for ingress in ingressarray:
    if ingress["ToPort"] not in ["443"]:
        ingress["CidrIp"] = ingresscidrblock
    else:
        ingress["CidrIp"] = "0.0.0.0/0"
egressarray = cftemplate["Resources"]["AppELBSG"]["Properties"]["SecurityGroupEgress"]
for egress in egressarray:
    egress["CidrIp"] = ingresscidrblock


cftemplate["Resources"]["UtlELBSG"]["Properties"]["SecurityGroupIngress"] = [
    {
        "IpProtocol": "tcp",
        "FromPort": "8080",
        "ToPort": "8080",
        "CidrIp": ingresscidrblock,
    },
    {
        "IpProtocol": "tcp",
        "FromPort": "3391",
        "ToPort": "3391",
        "CidrIp": ingresscidrblock,
    },
    {
        "IpProtocol": "tcp",
        "FromPort": "3389",
        "ToPort": "3389",
        "CidrIp": "24.55.11.229/32",
    },
    {
        "IpProtocol": "tcp",
        "FromPort": "3389",
        "ToPort": "3389",
        "CidrIp": "192.203.175.183/32",
    },
    {
        "IpProtocol": "tcp",
        "FromPort": "3389",
        "ToPort": "3389",
        "CidrIp": "192.203.177.183/32",
    },
    {
        "IpProtocol": "tcp",
        "FromPort": "3389",
        "ToPort": "3389",
        "CidrIp": "192.203.181.183/32",
    },
]

cftemplate["Resources"]["UtlELBSG"]["Properties"]["SecurityGroupEgress"] = [
    {
        "IpProtocol": "tcp",
        "FromPort": "8080",
        "ToPort": "8080",
        "CidrIp": ingresscidrblock,
    },
    {
        "IpProtocol": "tcp",
        "FromPort": "3389",
        "ToPort": "3389",
        "CidrIp": ingresscidrblock,
    },
]


cloudformationtemplate = "MicroStrategyOnAWS.json"
with open(cloudformationtemplate, "w") as outfile:
    json.dump(cftemplate, outfile, indent=2)

s3client = boto3.client("s3")

s3client.upload_file(
    cloudformationtemplate,
    s3Bucket,
    f"cloudformations/{cloudformationtemplate}",
    ExtraArgs={"ServerSideEncryption": "AES256"},
)
s3url = f"https://s3.amazonaws.com/{s3Bucket}/cloudformations/{cloudformationtemplate}"
print(s3url)
try:
    response = client.update_stack(
        StackName="MicroStrategyOnAWS",
        TemplateURL=s3url,
        UsePreviousTemplate=False,
        Parameters=[
            {"ParameterKey": "PublicSubnet01", "ParameterValue": args.publicsubnet01},
            {"ParameterKey": "PublicSubnet02", "ParameterValue": args.publicsubnet02},
            {"ParameterKey": "PrivateSubnet01", "ParameterValue": args.privatesubnet01},
            {"ParameterKey": "PrivateSubnet02", "ParameterValue": args.privatesubnet02},
            {"ParameterKey": "VPC", "ParameterValue": args.vpc},
            {"ParameterKey": "VPCCidrBlock", "ParameterValue": args.vpccidrblock},
        ],
        Capabilities=["CAPABILITY_NAMED_IAM"],
    )
    print(response)
except ClientError as e:
    if e.response["Error"]["Message"] == "No updates are to be performed.":
        print("no updates")
    else:
        raise e
