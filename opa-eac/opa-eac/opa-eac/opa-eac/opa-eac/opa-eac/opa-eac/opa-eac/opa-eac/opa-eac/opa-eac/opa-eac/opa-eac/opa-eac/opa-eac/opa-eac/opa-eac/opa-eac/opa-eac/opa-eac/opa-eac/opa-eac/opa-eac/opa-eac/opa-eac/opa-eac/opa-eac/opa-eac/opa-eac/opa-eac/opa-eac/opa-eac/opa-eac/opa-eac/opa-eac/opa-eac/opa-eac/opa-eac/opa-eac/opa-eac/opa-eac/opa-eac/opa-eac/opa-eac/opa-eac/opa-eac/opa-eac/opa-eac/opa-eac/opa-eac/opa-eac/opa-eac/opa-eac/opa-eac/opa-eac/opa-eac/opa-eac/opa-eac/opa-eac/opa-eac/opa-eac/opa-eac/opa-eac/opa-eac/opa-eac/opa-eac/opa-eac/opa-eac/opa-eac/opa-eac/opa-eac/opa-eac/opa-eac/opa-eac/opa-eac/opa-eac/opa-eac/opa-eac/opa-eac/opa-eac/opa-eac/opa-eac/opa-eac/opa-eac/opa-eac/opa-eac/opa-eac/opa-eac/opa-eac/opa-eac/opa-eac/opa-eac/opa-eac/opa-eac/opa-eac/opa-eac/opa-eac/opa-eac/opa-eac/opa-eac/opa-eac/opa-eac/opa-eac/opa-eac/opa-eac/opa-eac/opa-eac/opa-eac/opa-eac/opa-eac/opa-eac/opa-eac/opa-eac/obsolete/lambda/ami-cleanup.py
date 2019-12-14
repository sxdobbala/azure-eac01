import boto3
import os
from operator import itemgetter


def lambda_handler(event, context):

    aws_region = os.environ['region']
    account_owner_id = boto3.client('sts').get_caller_identity()['Account']
    source_ami_list = ['ami-00b0bc8fbd1090d30','ami-00d23047ffccdb0db','ami-65d3e81a','ami-c1003ebe']
    
    #number of AMI to keep for each source
    keep_ami_count = 2
    
    #connect to ec2
    ec2_client = boto3.client('ec2', region_name=aws_region)

    for source_ami in source_ami_list:
        print("------Source Image: %s-----" % source_ami)
        cleanup_counter = 0
        
        #get all images
        images_list = ec2_client.describe_images(
            Owners=[account_owner_id], 
            Filters=[{"Name": "tag:source_ami", "Values": [source_ami]}]
        )
        
        #sort images
        images_sorted = sorted(
            images_list["Images"], key=itemgetter("CreationDate"), reverse=True
        )
        print("Latest Image: %s" % (images_sorted[0]["ImageId"]))
        
        #get all snapshots
        snapshots = ec2_client.describe_snapshots(MaxResults=1000, OwnerIds=[account_owner_id])['Snapshots']
        
        #deregister images & delete respective snapshot
        for index in range(keep_ami_count,len(images_sorted)) :
            image_id = images_sorted[index]['ImageId']
            
            try:
                ec2_client.deregister_image(ImageId=image_id)
            except ClientError:
                pass
            print('Image %s is removed' % image_id)
            
            for snapshot in snapshots:
                if snapshot['Description'].find(image_id) > 0:
                    snap = ec2_client.delete_snapshot(SnapshotId=snapshot['SnapshotId'])
                    print("Deleting snapshot " + snapshot['SnapshotId'])

            cleanup_counter += 1
        
        print("Total number of ami's deregistered: %s" % cleanup_counter)

    return 'Done'  