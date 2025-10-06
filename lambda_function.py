import boto3
import os

ec2 = boto3.client('ec2')
sns = boto3.client('sns')

SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
DEFAULT_TAG_VALUE = os.environ.get('DEFAULT_TAG_VALUE', 'Daily')

def lambda_handler(event, context):
    try:
        volume_id = event['detail']['responseElements']['volumeId']
        
        # Describe volume
        response = ec2.describe_volumes(VolumeIds=[volume_id])
        tags = response['Volumes'][0].get('Tags', [])
        
        has_backup_tag = any(tag['Key'] == 'backup_frequency' for tag in tags)
        
        if not has_backup_tag:
            # Apply default tag
            ec2.create_tags(
                Resources=[volume_id],
                Tags=[{'Key': 'backup_frequency', 'Value': DEFAULT_TAG_VALUE}]
            )
            
            # Notify Security Team
            message = (f"EBS Volume {volume_id} was created without 'backup_frequency' tag.\n"
                       f"A default tag has been applied: backup_frequency={DEFAULT_TAG_VALUE}.")
            sns.publish(TopicArn=SNS_TOPIC_ARN, Message=message, Subject="EBS Missing Tag Alert")
        else:
            print(f"Volume {volume_id} already has backup_frequency tag.")
            
    except Exception as e:
        print(f"Error: {e}")
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=f"Error processing EBS tag check: {str(e)}",
            Subject="EBS Tagging Error"
        )
