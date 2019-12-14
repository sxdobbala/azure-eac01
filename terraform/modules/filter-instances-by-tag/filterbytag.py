import boto3
import sys
from terraform_external_data import terraform_external_data

@terraform_external_data
def filter_by_tag(query):
    kwargs = eval(query['tag_filters'])
    if query['resource_type'] == 'rds':
        response = filter_rds_by_tags(**kwargs)
        return response
    elif query['resource_type'] == 'redshift':
        response = filter_redshift_by_tags(**kwargs)
        return response
    elif query['resource_type'] == 'ec2':
        response = filter_ec2_by_tags(**kwargs)
        return response
    else: 
        raise Exception("Resource Type not supported")

def filter_redshift_by_tags(**filter_tags):
    tag_keys = []
    tag_values = []
    for key, value in filter_tags.items():
        tag_keys.append(key)
        tag_values.append(value)

    redshift = boto3.client('redshift')
    redshift_dict = redshift.describe_clusters(TagKeys=tag_keys, TagValues=tag_values)
    cluster_list = redshift_dict['Clusters']
    identifier_list = []

    for cluster in cluster_list:
        is_target = 1

        for key, value in filter_tags.items():
            single_tag_clusters_dict = redshift.describe_clusters(
                TagKeys=[
                    key,
                ],
                TagValues=[
                    value,
                ]
            )
            single_tag_cluster_list = single_tag_clusters_dict['Clusters']
            if cluster not in single_tag_cluster_list:
                is_target = 0
                break

        if is_target:
            identifier_list.append(cluster['ClusterIdentifier'])
    #external data only accepts result value as string
    response = ','.join(identifier_list)
    #result has to be in map format
    return {'filtered_instances_by_tags': str(response)}

def filter_rds_by_tags(**filter_tags):
    rds = boto3.client('rds')
    rds_dict = rds.describe_db_instances()
    instance_list = rds_dict['DBInstances']
    identifier_list = []

    for instance in instance_list:
        is_target = 1
        tag_response = rds.list_tags_for_resource(ResourceName=instance['DBInstanceArn'])
        #Get the list of Tags for each instance
        tag_list = tag_response['TagList']
        tag_key_list = []
        for tag in tag_list:
            tag_key_list.append(tag['Key'])

        for key, value in filter_tags.items():
            if key not in tag_key_list:
                is_target = 0
                break
            
            for tag in tag_list:
                if key == tag['Key'] and value != tag['Value']:
                    is_target = 0
                    break

        if is_target:
            identifier_list.append(instance['DBInstanceIdentifier'])
    #external data only accepts result value as string
    response = ','.join(identifier_list)
    #result has to be in map format
    return {'filtered_instances_by_tags': str(response)}

def filter_ec2_by_tags(**filter_tags):
    ec2 = boto3.client('ec2')
    ec2_dict = ec2.describe_instances()
    instance_list = ec2_dict['Reservations']
    identifier_list = []

    for instance in instance_list:
        is_target = 1
        instance_id = instance['Instances'][0]['InstanceId']

        for key, value in filter_tags.items():
            filter_name = 'tag:'+key
            single_tag_instances_dict = ec2.describe_instances(
                Filters=[
                    {
                        'Name': filter_name,
                        'Values': value.split(',')
                    },
                ]
            )
            single_tag_instances_list = single_tag_instances_dict['Reservations']
            
            if instance not in single_tag_instances_list:
                is_target = 0
                break
        
        if is_target:
            identifier_list.append(instance_id)
    
    response = ','.join(identifier_list)
    return {'filtered_instances_by_tags': str(response)}


if __name__ == "__main__":
    filter_by_tag()

