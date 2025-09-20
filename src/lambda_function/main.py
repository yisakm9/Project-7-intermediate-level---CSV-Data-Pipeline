import boto3
import os
import urllib.parse

s3_client = boto3.client('s3')
sfn_client = boto3.client('stepfunctions')

def lambda_handler(event, context):
    try:
        # Get the bucket and key from the S3 event
        bucket_name = event['Records'][0]['s3']['bucket']['name']
        s3_key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])

        print(f"File uploaded to {bucket_name}/{s3_key}. Moving to processed bucket.")

        dest_bucket_name = os.environ['DESTINATION_BUCKET']
        state_machine_arn = os.environ['STATE_MACHINE_ARN']
        
        # --- SIMPLIFIED LOGIC ---
        # Simply copy the raw file from the raw bucket to the processed bucket
        copy_source = {'Bucket': bucket_name, 'Key': s3_key}
        s3_client.copy_object(
            CopySource=copy_source,
            Bucket=dest_bucket_name,
            Key=s3_key
        )
        
        print(f"Successfully moved file to {dest_bucket_name}/{s3_key}")

        # After successfully moving, start the Step Function
        print(f"Starting Step Function execution for ARN: {state_machine_arn}")
        sfn_client.start_execution(stateMachineArn=state_machine_arn)
        print("Step Function started successfully.")
        
        return {
            'statusCode': 200,
            'body': f'File moved and orchestration started for {s3_key}.'
        }

    except Exception as e:
        print(f"Error processing file: {e}")
        raise e