import boto3
import argparse
import json

ssm = boto3.client("ssm")


def create_document(content):
    ssm.create_document(
        Content=content, Name="SSM-SessionManagerRunShell", DocumentType="Session"
    )
    return None


def update_document(content):
    ssm.update_document(
        Content=content, Name="SSM-SessionManagerRunShell", DocumentVersion="$LATEST"
    )
    return None


def get_document_json(s3_bucket_name, s3_key_prefix, cloudwatch_log_group_name):
    document = {
        "schemaVersion": "1.0",
        "description": "Document to hold regional settings for Session Manager",
        "sessionType": "Standard_Stream",
        "inputs": {
            "s3BucketName": f"{s3_bucket_name}",
            "s3KeyPrefix": f"{s3_key_prefix}",
            "s3EncryptionEnabled": "true",
            "cloudWatchLogGroupName": f"{cloudwatch_log_group_name}",
            "cloudWatchEncryptionEnabled": "true",
        },
    }

    return json.dumps(document)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="")
    parser.add_argument("--s3_bucket_name", type=str, help="", required="true")
    parser.add_argument("--s3_key_prefix", type=str, help="", required="true")
    parser.add_argument(
        "--cloudwatch_log_group_name", type=str, help="", required="true"
    )
    args = parser.parse_args()

    content = get_document_json(
        args.s3_bucket_name, args.s3_key_prefix, args.cloudwatch_log_group_name
    )

    try:
        create_document(content)
    except ssm.exceptions.DocumentAlreadyExists:
        try:
            update_document(content)
        except ssm.exceptions.DuplicateDocumentContent:
            # pass on exception thrown for updating with identical content
            pass

