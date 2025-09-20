import pandas as pd
import boto3
import io
import os
import json

# Initialize clients
s3_client = boto3.client('s3')
sfn_client = boto3.client('stepfunctions')

def lambda_handler(event, context):
    # --- THIS IS THE FIX ---
    # Define variables with default values before the try block
    bucket_name = None
    s3_key = None

    try:
        # Get the bucket and key from the S3 event
        bucket_name = event['Records'][0]['s3']['bucket']['name']
        s3_key = event['Records'][0]['s3']['object']['key']

        print(f"File uploaded to {bucket_name}/{s3_key}")

        # Define the destination bucket and state machine ARN from environment variables
        dest_bucket_name = os.environ['DESTINATION_BUCKET']
        state_machine_arn = os.environ['STATE_MACHINE_ARN']
        
        # Read the CSV file from the raw bucket
        response = s3_client.get_object(Bucket=bucket_name, Key=s3_key)
        df = pd.read_csv(io.BytesIO(response['Body'].read()))

        # Data Cleaning Logic
        df.dropna(inplace=True)
        
        print(f"Cleaned DataFrame. Shape: {df.shape}")

        # Convert the DataFrame back to a CSV in memory
        output_buffer = io.StringIO()
        df.to_csv(output_buffer, index=False)
        
        # Upload the cleaned CSV to the processed bucket
        s3_client.put_object(
            Bucket=dest_bucket_name,
            Key=s3_key,
            Body=output_buffer.getvalue()
        )
        
        print(f"Successfully processed and uploaded to {dest_bucket_name}/{s3_key}")

        # After successfully writing, start the Step Function
        print(f"Starting Step Function execution for ARN: {state_machine_arn}")
        
        sfn_client.start_execution(
            stateMachineArn=state_machine_arn
        )

        print("Step Function started successfully.")
        
        return {
            'statusCode': 200,
            'body': f'Successfully processed {s3_key} and started orchestration.'
        }

    except Exception as e:
        # Now the error message can safely reference the key, even if it's None
        print(f"Error processing file {s3_key} from bucket {bucket_name}: {e}")
        raise e