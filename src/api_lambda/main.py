import boto3
import time
import os
import json

athena_client = boto3.client('athena')

def lambda_handler(event, context):
    # Get configuration from environment variables
    DATABASE_NAME = os.environ['ATHENA_DATABASE']
    TABLE_NAME = os.environ['ATHENA_TABLE']
    RESULT_OUTPUT_LOCATION = os.environ['ATHENA_OUTPUT_S3_PATH']

    # The SQL query to run
    query = f'SELECT * FROM "{TABLE_NAME}";'

    try:
        # Start the Athena query execution
        response = athena_client.start_query_execution(
            QueryString=query,
            QueryExecutionContext={'Database': DATABASE_NAME},
            ResultConfiguration={'OutputLocation': RESULT_OUTPUT_LOCATION}
        )
        query_execution_id = response['QueryExecutionId']

        # Poll for the query to complete
        while True:
            stats = athena_client.get_query_execution(QueryExecutionId=query_execution_id)
            status = stats['QueryExecution']['Status']['State']
            if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
                break
            time.sleep(1) # Wait 1 second before checking again

        if status != 'SUCCEEDED':
            raise Exception(f"Athena query failed: {stats['QueryExecution']['Status']['StateChangeReason']}")

        # Get the query results
        results_paginator = athena_client.get_paginator('get_query_results')
        results_iter = results_paginator.paginate(
            QueryExecutionId=query_execution_id,
            PaginationConfig={'PageSize': 1000}
        )
        
        # Format the results into a clean JSON array
        data = []
        rows = [row for page in results_iter for row in page['ResultSet']['Rows']]
        
        # First row is header, so skip it (start from index 1)
        header = [d['VarCharValue'] for d in rows[0]['Data']]
        
        for row in rows[1:]:
            item_data = {}
            for i, value in enumerate(row['Data']):
                # Convert column names from "Item Type" to "item_type" for easier JS access
                clean_header = header[i].lower().replace(' ', '_')
                item_data[clean_header] = value.get('VarCharValue')
            data.append(item_data)
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*', # Allow requests from any origin
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET,OPTIONS'
            },
            'body': json.dumps(data)
        }

    except Exception as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': str(e)})
        }