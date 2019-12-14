#!/usr/bin/env python3
import subprocess
import boto3
from ec2_metadata import ec2_metadata
import logging
import sys

logging.basicConfig(stream=sys.stdout)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def update_key():
    ssm = boto3.client("ssm", region_name=ec2_metadata.region)
    response = ssm.get_parameter(Name="mstr.pre-activated-license-key", WithDecryption=True)
    key = response["Parameter"]["Value"]
    logger.info("Assuming not activated: Running MSTR License Manager to update the License Key")
    p = subprocess.Popen('/opt/mstr/MicroStrategy/bin/mstrlicmgr -console', shell=True, stdin=subprocess.PIPE,
                          stdout=subprocess.PIPE, universal_newlines=True)
    # When status is inactive, the option is "4"
    p.stdin.write('4\n'+key+'\n')
    logger.info("closing mstrlicmmgr console")
    p.stdin.close()

if __name__ == "__main__":
    update_key()