#!/usr/bin/env python3

import json
import boto3
from collections import OrderedDict
from operator import itemgetter
from sys import argv
import subprocess
import argparse
import threading
import os

import boto3
import json
from botocore.exceptions import ClientError, ParamValidationError


def lambda_handler(event, context):
    version = context["mstrversion"]

    print("--------------------------------------")
    cloudformationtemplate = "create-enterprise-instance-2linux-1windows-1RDS.json"

    s3 = boto3.resource("s3")
    print(cloudformationtemplate)
    obj = s3.Object(
        "securecloud-config-prod-us-east-1", "cloudformations/" + cloudformationtemplate
    )
    data = json.loads(obj.get()["Body"].read().decode("utf-8"))

    supported_versions = [version]
    supported_types = ["AmazonAMIMap"]
    supported_regions = ["us-east-1"]
    for version in supported_versions:
        print("\n-------Version " + version + "---------------------------")
        for amitype in supported_types:
            print("AMI Type " + amitype)
            for myregion in supported_regions:
                print("Region " + myregion)

                origimage = data["Mappings"][amitype][myregion][version]
                print("originalami [" + origimage)
                return origimage

    return ""

