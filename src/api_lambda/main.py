import boto3
import time
import os
import json

athena_client = boto3.client('athena')

def lambda_handler(event, context):
    """
    This Lambda function is invoked by API Gateway.
    It queries the final, aggregated sales data from Amazon Athena,
    formats it as JSON, and returns it to the frontend.
    """
    DATABASE_NAME = os.environ['ATHENA_DATABASE']
    TABLE_NAME = os.environ['ATHENA_TABLE']
    RESULT_OUTPUT_LOCATION = os.environ['ATHENA_OUTPUT_S3_PATH']
    query = f'SELECT * FROM "{TABLE_NAME}";'

    print(f"Starting Athena query on database '{DATABASE_NAME}' and table '{TABLE_NAME}'")

    try:
        # Step 1: Start the Athena query execution
        response = athena_client.start_query_execution(
            QueryString=query,
            QueryExecutionContext={'Database': DATABASE_NAME},
            ResultConfiguration={'OutputLocation': RESULT_OUTPUT_LOCATION}
        )
        query_execution_id = response['QueryExecutionId']
        print(f"Started query execution with ID: {query_execution_id}")

        # Step 2: Poll for the query to complete
        while True:
            stats = athena_client.get_query_execution(QueryExecutionId=query_execution_id)
            status = stats['QueryExecution']['Status']['State']
            if status in ['SUCCEEDED', 'FAILED', 'CANCELLED']:
                print(f"Query finished with status: {status}")
                break
            time.sleep(1) # Wait 1 second before checking again

        if status != 'SUCCEEDED':
            error_reason = stats['QueryExecution']['Status'].get('StateChangeReason', 'Unknown error')
            raise Exception(f"Athena query failed: {error_reason}")

        # Step 3: Get and format the results
        results_paginator = athena_client.get_paginator('get_query_results')
        results_iter = results_paginator.paginate(
            QueryExecutionId=query_execution_id,
            PaginationConfig={'PageSize': 1000}
        )

        data = []
        # Get all rows from all pages
        rows = [row for page in results_iter for row in page['ResultSet']['Rows']]

        # Handle case where the table is empty (only a header row)
        if not rows or len(rows) <= 1:
            print("Query returned no data rows.")
            # Return an empty array, which the frontend expects
            return {
                'statusCode': 200,
                'headers': {'Access-Control-Allow-Origin': '*'},
                'body': json.dumps([])
            }

        # The first row is the header.
        header = [d['VarCharValue'] for d in rows[0]['Data']]

        # Process the data rows
        for row in rows[1:]:
            item_data = {}
            for i, value in enumerate(row['Data']):
                # --- THE FIX ---
                # No cleaning is needed. The headers from Athena are now guaranteed
                # to be clean (e.g., 'item_type'), so we use them directly as keys.
                item_data[header[i]] = value.get('VarCharValue')
            data.append(item_data)

        print(f"Final data being returned: {json.dumps(data)}")

        return {
            'statusCode': 200,
            'headers': {
                # Add all necessary CORS headers for a professional API
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET,OPTIONS'
            },
            'body': json.dumps(data)
        }

    except Exception as e:
        print(f"Error processing Athena query: {e}")
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': str(e)})
        }