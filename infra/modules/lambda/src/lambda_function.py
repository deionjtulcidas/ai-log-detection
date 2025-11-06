import json
import boto3
import os

sns = boto3.client('sns')
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

def lambda_handler(event, context):
    for record in event['Records']:
        s3_info = record['s3']
        bucket = s3_info['bucket']['name']
        key = s3_info['object']['key']

        print(f"Processing log file: {key} from bucket: {bucket}")

        if "error" in key.lower() or "unauthorized" in key.lower():
            message = f"Anomaly detected in {key} — unauthorized access or error pattern found."
            print(message)
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject="AI Log Detection Alert",
                Message=message
            )
        else:
            print(f"No anomaly detected for {key}.")

    return {
        'statusCode': 200,
        'body': json.dumps('Processing complete')
    }
