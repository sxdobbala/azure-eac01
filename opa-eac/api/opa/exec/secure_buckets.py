"""
Lambda function queries AWS ConfigService to find S3 buckets which are not SSL-compliant (i.e. allow non-SSL connections). 
It then proceeds to add a policy statement restricting communication over SSL only.

The lambda can be invoked by itself and will work as expected. However, the presumption is that it will be invoked via SNS
as a remediation step for non-compliance to the AWS Config rule S3_BUCKET_SSL_REQUESTS_ONLY.
See: https://console.aws.amazon.com/config/home?region=us-east-1#/rules/rule-details/S3_BUCKET_SSL_REQUESTS_ONLY

That said, the remediation does not happen automatically but is triggered manually from AWS Config.
For this reason, this lambda is also scheduled to run every hour via a CloudWatch rule.
"""

import json
import boto3
import botocore

s3 = boto3.client("s3")
config = boto3.client("config")


def lambda_handler(event, context):
    for bucket in get_non_compliant_buckets():
        add_ssl_policy(bucket)


def get_non_compliant_buckets():
    next_token = ""
    buckets = []

    while next_token is not None:
        compliance_details = config.get_compliance_details_by_config_rule(
            ConfigRuleName="S3_BUCKET_SSL_REQUESTS_ONLY",
            ComplianceTypes=["NON_COMPLIANT"],
            Limit=100,
            NextToken=next_token,
        )

        results = compliance_details["EvaluationResults"]
        buckets += [
            result["EvaluationResultIdentifier"]["EvaluationResultQualifier"][
                "ResourceId"
            ]
            for result in results
        ]
        next_token = compliance_details.get("NextToken", None)

    return buckets


def get_ssl_policy():
    with open("ssl_policy.json", "r") as f:
        policy = json.loads(f.read())
        return policy


def add_ssl_policy(bucket):
    ssl_required = get_ssl_policy()
    ssl_required["Statement"][0]["Resource"] = f"arn:aws:s3:::{bucket}/*"

    try:
        result = s3.get_bucket_policy(Bucket=bucket)
        policy = json.loads(result["Policy"])
        policy["Statement"].insert(0, ssl_required["Statement"][0])

    # this happens when no bucket policy exists
    except botocore.exceptions.ClientError:
        policy = ssl_required

    s3.put_bucket_policy(
        Bucket=bucket, ConfirmRemoveSelfBucketAccess=False, Policy=json.dumps(policy)
    )

    print(f"Bucket policy for {bucket} updated: {json.dumps(policy)}")


if __name__ == "__main__":
    lambda_handler(None, None)
