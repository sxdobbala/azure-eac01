import boto3
import json
import os
from botocore.exceptions import ClientError, ParamValidationError

def lambda_handler(event, context):
    print(json.dumps(event))
    event["Description"] += " Optum"
    if event["Resources"].get("RDSMySQL", "") != "":
        event["Resources"]["RDSMySQL"]["Properties"]["StorageEncrypted"] = "True"
    if event["Resources"].get("RDSInstanceType", "") != "":
        event["Parameters"]["RDSInstanceType"]["Default"] = "db.r4.large"

    # add platformInstance monitoring and tags
    if event["Resources"].get("PlatformInstance", "") != "":
        event["Resources"]["PlatformInstance"]["Properties"]["Monitoring"] = "True"
        event["Resources"]["PlatformInstance"]["Properties"]["Tags"].append(
            {"Value": "1", "Key": "aws_inspector"}
        )
    for x in range(1, 9):
        strx = str(x)
        if event["Resources"].get("PlatformInstance0" + strx, "") != "":
            print(str(x) + " linux")
            event["Resources"]["PlatformInstance0" + strx]["Properties"][
                "Monitoring"
            ] = "True"
            event["Resources"]["PlatformInstance0" + strx]["Properties"]["Tags"].append(
                {"Value": "1", "Key": "aws_inspector"}
            )
    if event["Resources"].get("EFSFileSystem", "") != "":
        event["Resources"]["EFSFileSystem"]["Properties"]["Encrypted"] = "True"

        # update efs code deploy dependency
        event["Resources"]["PlatformInfraEntrCDDeploymentGroup"]["DependsOn"].append(
            "EFSMountTarget1"
        )
        event["Resources"]["PlatformInfraEntrCDDeploymentGroup"]["DependsOn"].append(
            "EFSMountTarget2"
        )

        # update usher dependency for enterprise
        event["Resources"]["PlatformRestartServerCDDeploymentGroup"]["DependsOn"] = [
            "PlatformWebCDDeploymentGroup"
        ]
        # update enterprise-specific CD images
        event["Resources"]["PlatformInfraEntrCDDeploymentGroup"]["Properties"]["Deployment"]["Revision"]["S3Location"]["Key"]["Fn::Join"][1][1] = "LinuxEnterpriseConfigOptum.zip"
        event["Resources"]["PlatformRestartServerCDDeploymentGroup"]["Properties"]["Deployment"]["Revision"]["S3Location"]["Key"]["Fn::Join"][1][1] = "RestartServersOptum.zip"

    else:
        print("department or team instance")
        # update usher dependency for team
        event["Resources"]["PlatformEmailCDDeploymentGroup"]["DependsOn"] = [
            "PlatformWebCDDeploymentGroup"
        ]

    # equivalent to forcing condition to False, ignoring input IncludeUsher parameter
    event["Conditions"]["RunUsher"] = {"Fn::Equals": ["1", "0"]}

    print(json.dumps(event))
    return {"statusCode": 200, "body": json.dumps(event)}

if __name__ == "__main__":
    # TODO: move this to a real unit test

    import yaml # not available on Lambda by default, only need for testing
    s3 = boto3.client("s3")
    obj = s3.get_object(Bucket="securecloud-config-prod-us-east-1", Key="cloudformations/create-enterprise-instance-16linux-1windows-1RDS.json")
    event = yaml.load(obj["Body"].read().decode("utf-8"))

    result = json.loads(lambda_handler(event, {})["body"])
    print("*** test output ***")
    print(result["Resources"]["PlatformProductsCDDeploymentGroup"])
    print(result["Conditions"]["RunUsher"])

