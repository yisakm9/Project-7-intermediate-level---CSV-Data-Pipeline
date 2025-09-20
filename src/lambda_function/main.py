import pandas as pd
import boto3
import io
import os
import json

s3_client = boto3.client('s3')
sfn_client = boto3.client('stepfunctions')

def lambda_handler(event, context):
    bucket_name = None
    s3_key = None

    try:
        bucket_name = event['Records'][0]['s3']['bucket']['name']
        s3_key = event['Records'][0]['s3']['object']['key']

        print(f"File uploaded to {bucket_name}/{s3_key}")

        dest_bucket_name = os.environ['DESTINATION_BUCKET']
        state_machine_arn = os.environ['STATE_MACHINE_ARN']
        
        response = s3_client.get_object(Bucket=bucket_name, Key=s3_key)

        # --- THIS IS THE FINAL FIX ---
        # Tell pandas to treat empty strings ('') as missing values (NaN).
        df = pd.read_csv(io.BytesIO(response['Body'].read()), na_values=[''])

        # Now, dropna() will correctly identify and remove the row with the missing Unit Price.
        df.dropna(inplace=True)
        
        print(f"Cleaned DataFrame. Shape: {df.shape}")

        output_buffer = io.StringIO()
        df.to_csv(output_buffer, index=False)
        
        s3_client.put_object(
            Bucket=dest_bucket_name,
            Key=s3_key,
            Body=output_buffer.getvalue()
        )
        
        print(f"Successfully processed and uploaded to {dest_bucket_name}/{s3_key}")

        print(f"Starting Step Function execution for ARN: {state_machine_arn}")
        sfn_client.start_execution(stateMachineArn=state_machine_arn)
        print("Step Function started successfully.")
        
        return {
            'statusCode': 200,
            'body': f'Successfully processed {s3_key} and started orchestration.'
        }

    except Exception as e:
        print(f"Error processing file {s3_key} from bucket {bucket_name}: {e}")
        raise e