import boto3
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def get_tags_with_key_prefix(env_id, tag_key_prefix):
    total_results = get_resources_response(env_id)
    tags = [resource["Tags"] for resource in total_results]
    result = dict()
    for tag in tags[0]:
        if tag['Key'].startswith(tag_key_prefix):
            result[tag['Key']]= tag['Value']
    
    return result

def apply_tags_to_redshift(redshift_id, tags):
    logger.info(f"Applying tags: {tags} to redshift cluster {redshift_id}")
    region = boto3.session.Session().region_name
    account_id = boto3.client('sts').get_caller_identity().get('Account')
    resource_arn_list = [f"arn:aws:redshift:{region}:{account_id}:cluster:{redshift_id}"] 
    tag_resources(resource_arn_list, tags)

def apply_tags_to_ec2(env_id, tags):
    logger.info(f"Applying tags: {tags} to EC2 instances with stack name: {env_id}")
    total_results = get_resources_response(env_id)
    resource_arn_list = [resource["ResourceARN"] for resource in total_results]
    tag_resources(resource_arn_list, tags)

def get_resources_response(env_id):
    total_results = []
    page_token = ""
    response = search_ec2_resources(page_token, env_id)

    if not "ResourceTagMappingList" in response:
        raise Exception(f"No EC2 instance found for stack name: {env_id}")

    while True:
        total_results += response["ResourceTagMappingList"]
        page_token = response["PaginationToken"]
        if not page_token:
            break
        response = search_ec2_resources(page_token, env_id)

    return total_results

def search_ec2_resources(token, env_id):
    client = boto3.client("resourcegroupstaggingapi")
    response = client.get_resources(
        PaginationToken=token,
        ResourcesPerPage=100,
        ResourceTypeFilters=["ec2:instance"],
        TagFilters=[{"Key": "aws:cloudformation:stack-name", "Values": [env_id]}],
    )
    return response


def tag_resources(resource_arn_list, tags):
    client = boto3.client("resourcegroupstaggingapi")
    response = client.tag_resources(ResourceARNList=resource_arn_list, Tags=tags)
    if response["FailedResourcesMap"]:
        raise Exception(
            f"Details of resources that could not be tagged: {response['FailedResourcesMap']}"
        )