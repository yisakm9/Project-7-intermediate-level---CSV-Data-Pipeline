import pandas as pd
import boto3
import io
import os

# Initialize S3 client
s3_client = boto3.client('s3')

def lambda_handler(event, context):
    """
    This Lambda function is triggered by an S3 event.
    It reads the uploaded CSV, cleans it using pandas, 
    and saves the cleaned CSV to the processed bucket.
    """
    try:
        # Get the bucket and key from the S3 event
        bucket_name = event['Records'][0]['s3']['bucket']['name']
        s3_key = event['Records'][0]['s3']['object']['key']

        print(f"File uploaded to {bucket_name}/{s3_key}")

        # Define the destination bucket from environment variables
        dest_bucket_name = os.environ['DESTINATION_BUCKET']
        
        # Read the CSV file from the raw bucket
        response = s3_client.get_object(Bucket=bucket_name, Key=s3_key)
        # The object's body is a streaming body, read it into a pandas DataFrame
        df = pd.read_csv(io.BytesIO(response['Body'].read()))

        # --- Data Cleaning Logic ---
        # 1. Drop rows with any missing values. This is a simple cleaning step.
        df.dropna(inplace=True)
        # 2. You could add more complex logic here (e.g., type casting, column renaming)
        
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
        
        return {
            'statusCode': 200,
            'body': f'Successfully processed {s3_key}'
        }

    except Exception as e:
        print(f"Error processing file: {e}")
        raise e