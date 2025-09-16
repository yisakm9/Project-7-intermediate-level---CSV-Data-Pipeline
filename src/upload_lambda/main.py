import boto3
import json
import os
import logging

s3_client = boto3.client('s3')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Generates an S3 pre-signed URL for uploading a file.
    """
    try:
        # Get the filename from the query string parameters
        query_params = event.get('queryStringParameters', {})
        file_name = query_params.get('filename')

        if not file_name:
            raise ValueError("Query parameter 'filename' is required.")

        bucket_name = os.environ['UPLOAD_BUCKET']
        
        # Generate the pre-signed URL for a PUT request
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={'Bucket': bucket_name, 'Key': file_name, 'ContentType': 'text/csv'},
            ExpiresIn=3600  # URL is valid for 1 hour
        )

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*', # Enable CORS
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET,PUT,OPTIONS'
            },
            'body': json.dumps({'uploadUrl': presigned_url, 'key': file_name})
        }

    except Exception as e:
        logger.error(f"Error generating pre-signed URL: {e}")
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': str(e)})
        }