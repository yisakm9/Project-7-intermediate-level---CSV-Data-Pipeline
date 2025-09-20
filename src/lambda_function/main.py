import pandas as pd
import boto3
import io
import os
import json # Import json

# Initialize clients
s3_client = boto3.client('s3')
sfn_client = boto3.client('stepfunctions') # Add Step Functions client

def lambda_handler(event, context):
    # ... (the first part of the function is the same)
    
    try:
        # ... (get bucket_name, s3_key, dest_bucket_name)

        # ... (read, clean, and write the CSV to the processed bucket)

        # --- THIS IS THE FIX ---
        # After successfully writing to the processed bucket, start the Step Function
        state_machine_arn = os.environ['STATE_MACHINE_ARN']
        
        print(f"Starting Step Function execution for ARN: {state_machine_arn}")
        
        sfn_client.start_execution(
            stateMachineArn=state_machine_arn,
            # We can optionally pass data to the state machine, but not needed here
            # input=json.dumps({'s3_key': s3_key}) 
        )

        print("Step Function started successfully.")
        
        return {
            'statusCode': 200,
            'body': f'Successfully processed {s3_key} and started orchestration.'
        }
    
    except Exception as e:
        print(f"Error processing file: {e}")
        raise e