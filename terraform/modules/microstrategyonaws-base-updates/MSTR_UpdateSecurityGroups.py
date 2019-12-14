import boto3
import json
import os
from botocore.exceptions import ClientError, ParamValidationError


def lambda_handler(event, context):
    print(json.dumps(event))
    ingresscidrblock = os.environ["INGRESS_CIDR_BLOCK"]
    is_prod = os.environ["IS_PROD"]
    appstream_sg_id = os.environ["APPSTREAM_SG_ID"]
    event["Description"] += " SGUpdate"

    event["Resources"]["PlatformInstanceSG"]["Properties"]["SecurityGroupEgress"] = [
        {
            "IpProtocol": "tcp",
            "FromPort": "443",
            "ToPort": "443",
            "CidrIp": "0.0.0.0/0",
        },
        {"IpProtocol": "tcp", "FromPort": "80", "ToPort": "80", "CidrIp": "0.0.0.0/0"},
    ]

    # allow ingress to PlatformInstanceSG from Appstream SG for SSH
    event["Resources"]["PlatformInstanceAllowSSHFromAppstream"] = {
        "Type": "AWS::EC2::SecurityGroupIngress",
        "Properties": {
            "IpProtocol": "tcp",
            "FromPort": "22",
            "ToPort": "22",
            "SourceSecurityGroupId": appstream_sg_id,
            "GroupId": {"Fn::GetAtt": ["PlatformInstanceSG", "GroupId"]},
        },
    }

    # allow ingress to PlatformInstanceSG from Appstream SG for i-server
    event["Resources"]["PlatformInstanceAllowIServerFromAppstream"] = {
        "Type": "AWS::EC2::SecurityGroupIngress",
        "Properties": {
            "IpProtocol": "tcp",
            "FromPort": "34952",
            "ToPort": "34952",
            "SourceSecurityGroupId": appstream_sg_id,
            "GroupId": {"Fn::GetAtt": ["PlatformInstanceSG", "GroupId"]},
        },
    }

    if is_prod == "false":
        event["Resources"]["PlatformInstanceSG"]["Properties"][
            "SecurityGroupIngress"
        ] = [
            {
                "IpProtocol": "tcp",
                "FromPort": "22",
                "ToPort": "22",
                "CidrIp": "10.0.0.0/8",
            },
            {
                "IpProtocol": "tcp",
                "FromPort": "34952",
                "ToPort": "34952",
                "CidrIp": "10.0.0.0/8",
            },
        ]

    if event["Resources"].get("RDSInstanceSG", "") != "":
        # DB port is dynamic depending on specified engine
        db_port_lookup = {
          "Fn::FindInMap": [
            "RDSTypeMap",
            {
              "Ref": "RDSEngineType"
            },
            "Port"
          ]
        }

        event["Resources"]["PlatformInstanceSG"]["Properties"][
            "SecurityGroupEgress"
        ].extend(
            [
                {
                    "IpProtocol": "tcp",
                    "FromPort": db_port_lookup,
                    "ToPort": db_port_lookup,
                    "DestinationSecurityGroupId": {
                        "Fn::GetAtt": ["RDSInstanceSG", "GroupId"]
                    },
                }
            ]
        )
        # allow ingress to RDSInstanceSG from Appstream SG
        event["Resources"]["RDSInstanceAllowFromAppstream"] = {
            "Type": "AWS::EC2::SecurityGroupIngress",
            "Properties": {
                "IpProtocol": "tcp",
                "FromPort": db_port_lookup,
                "ToPort": db_port_lookup,
                "SourceSecurityGroupId": appstream_sg_id,
                "GroupId": {"Fn::GetAtt": ["RDSInstanceSG", "GroupId"]},
            },
        }

    if event["Resources"].get("EFSSecurtyGroup", "") != "":
        event["Resources"]["PlatformInstanceSG"]["Properties"][
            "SecurityGroupEgress"
        ].extend(
            [
                {
                    "IpProtocol": "udp",
                    "FromPort": "2049",
                    "ToPort": "2049",
                    "DestinationSecurityGroupId": {
                        "Fn::GetAtt": ["EFSSecurtyGroup", "GroupId"]
                    },
                },
                {
                    "IpProtocol": "tcp",
                    "FromPort": "2049",
                    "ToPort": "2049",
                    "DestinationSecurityGroupId": {
                        "Fn::GetAtt": ["EFSSecurtyGroup", "GroupId"]
                    },
                },
            ]
        )
    # add sg allowing traffic from platform instance to self
    event["Resources"]["PlatformInstanceAllowToPlatformInstance"] = {
        "Type": "AWS::EC2::SecurityGroupEgress",
        "Properties": {
            "IpProtocol": "-1",
            "DestinationSecurityGroupId": {
                "Fn::GetAtt": ["PlatformInstanceSG", "GroupId"]
            },
            "GroupId": {"Fn::GetAtt": ["PlatformInstanceSG", "GroupId"]},
        },
    }
    event["Resources"]["PlatformELBSGCustomer"]["Properties"][
        "SecurityGroupIngress"
    ] = [
        {
            "IpProtocol": "tcp",
            "FromPort": "1443",
            "ToPort": "1443",
            "CidrIp": ingresscidrblock,
        },
        {
            "IpProtocol": "tcp",
            "FromPort": "2443",
            "ToPort": "2443",
            "CidrIp": ingresscidrblock,
        },
        {
            "IpProtocol": "tcp",
            "FromPort": "3443",
            "ToPort": "3443",
            "CidrIp": ingresscidrblock,
        },
        {
            "IpProtocol": "tcp",
            "FromPort": "4443",
            "ToPort": "4443",
            "CidrIp": ingresscidrblock,
        },
        {
            "IpProtocol": "tcp",
            "FromPort": "443",
            "ToPort": "443",
            "CidrIp": "0.0.0.0/0",
        },
        {
            "IpProtocol": "tcp",
            "FromPort": "34952",
            "ToPort": "34952",
            "CidrIp": ingresscidrblock,
        },
        {
            "IpProtocol": "tcp",
            "FromPort": "34962",
            "ToPort": "34962",
            "CidrIp": ingresscidrblock,
        },
        {
            "IpProtocol": "tcp",
            "FromPort": "3000",
            "ToPort": "3000",
            "CidrIp": ingresscidrblock,
        },
        {
            "IpProtocol": "tcp",
            "FromPort": "9443",
            "ToPort": "9443",
            "CidrIp": ingresscidrblock,
        },
    ]
    print(json.dumps(event))
    return {"statusCode": 200, "body": json.dumps(event)}


if __name__ == "__main__":
    # TODO: move this to a real unit test

    import yaml  # not available on Lambda by default, only need for testing

    s3 = boto3.client("s3")
    obj = s3.get_object(
        Bucket="securecloud-config-prod-us-east-1",
        Key="cloudformations/create-enterprise-instance-16linux-1windows-1RDS.json",
    )

    event = yaml.load(obj["Body"].read().decode("utf-8"))

    os.environ["INGRESS_CIDR_BLOCK"] = "10.0.0.0/8"
    os.environ["APPSTREAM_SG_ID"] = "sg-123456"
    os.environ["IS_PROD"] = "false"

    result = json.loads(lambda_handler(event, {})["body"])
    print("*** test output ***")
    print(result["Resources"]["RDSInstanceSG"])
    print(result["Resources"]["RDSInstanceAllowFromAppstream"])
    print(result["Resources"]["RDSInstanceAllowfromPlatformInstance"])
    print(result["Resources"]["PlatformInstanceAllowSSHFromAppstream"])
    print(result["Resources"]["PlatformInstanceAllowIServerFromAppstream"])
