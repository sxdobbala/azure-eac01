import boto3
import json
from botocore.exceptions import ClientError, ParamValidationError
from operator import itemgetter


def lambda_handler(event, context):
    ec2client = boto3.client("ec2")
    print(json.dumps(event))
    supported_versions = ["101101", "110101", "110200"]
    supported_types = ["AmazonAMIMap"]
    supported_regions = ["us-east-1"]
    event["Description"] += " Packed Encrypted"
    if event["Resources"].get("PlatformInstance", "") != "":
        event["Resources"]["PlatformInstance"]["Properties"]["BlockDeviceMappings"] = []
    for x in range(1, 9):
        strx = str(x)
        if event["Resources"].get("PlatformInstance0" + strx, "") != "":
            print(str(x) + " linux")
            event["Resources"]["PlatformInstance0" + strx]["Properties"][
                "BlockDeviceMappings"
            ] = []

    for amitype in supported_types:
        print("AMI Type " + amitype)

        for myregion in supported_regions:
            print("Region " + myregion)

            for version in supported_versions:
                print("\n-------Version " + version + "--------------")

                origimage = event["Mappings"][amitype][myregion][version]
                print("originalami [" + origimage)

                myimages = ec2client.describe_images(
                    Owners=["self"],
                    Filters=[{"Name": "tag:source_ami", "Values": [origimage]}],
                )
                myimages_sorted = sorted(
                    myimages["Images"], key=itemgetter("CreationDate"), reverse=True
                )
                if len(myimages_sorted) > 0:
                    newimage = myimages_sorted[0]["ImageId"]
                    print("newami [" + newimage)
                    event["Mappings"][amitype][myregion][version] = newimage
    print(json.dumps(event))
    return {"statusCode": 200, "body": json.dumps(event)}

