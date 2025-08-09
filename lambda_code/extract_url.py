import boto3
import json
import requests
import uuid
import os
from urllib.parse import unquote_plus
from datetime import datetime

s3_client = boto3.client('s3')
region_name = os.environ.get('AWS_REGION_')
dynamodb = boto3.resource('dynamodb', region_name=region_name)

# It's good practice to get the table name from an environment variable too
DECODED_URLS_TABLE_NAME = os.environ.get('DECODED_URLS_TABLE_NAME')
API_URL = os.environ.get('API_URL')

def lambda_handler(event, context):
    try:
        print("EVENT:", json.dumps(event))

        if not API_URL:
            raise ValueError("API_URL environment variable is not set.")

        for record in event['Records']:
            # 1. Extract S3 details
            bucket = record['s3']['bucket']['name']
            key = unquote_plus(record['s3']['object']['key'])
            print(f"Processing S3 object: s3://{bucket}/{key}")

            # 2. CRITICAL STEP: Get the S3 object's metadata to find the user_id
            try:
                head_response = s3_client.head_object(Bucket=bucket, Key=key)
                metadata = head_response.get('Metadata', {})
                user_id = metadata.get('user_id')

                if not user_id:
                    # Fail fast if the uploader did not include the user_id.
                    # This prevents anonymous data from entering the system.
                    print(f"ERROR: 'user_id' metadata not found on S3 object: {key}. Skipping record.")
                    continue

                print(f"Found user_id in metadata: {user_id}")

            except s3_client.exceptions.NoSuchKey:
                print(f"ERROR: S3 object not found: {key}. Skipping record.")
                continue

            # 3. Download the image and send to Render API
            response = s3_client.get_object(Bucket=bucket, Key=key)
            image_bytes = response['Body'].read()
            
            api_response = requests.post(API_URL, files={'image': image_bytes})
            api_response.raise_for_status()

            decoded_data_list = api_response.json().get('data')
            if not decoded_data_list:
                print(f"No QR code found in image: {key}. Skipping record.")
                continue

            decoded_url = decoded_data_list[0]
            print(f"Decoded URL: {decoded_url}")

            # 4. Store in DynamoDB with the CORRECT user_id
            table = dynamodb.Table(DECODED_URLS_TABLE_NAME)
            item = {
                'id': str(uuid.uuid4()),
                'decoded_url': decoded_url,
                's3_image_key': key,
                'scan_timestamp': datetime.utcnow().isoformat(),
                'status': 'decoded',
                'user_id': user_id
            }

            table.put_item(Item=item)
            print("Successfully stored item in DynamoDB:", item)

        return {"statusCode": 200, "body": "Processed all records successfully."}

    except Exception as e:
        print(f"FATAL ERROR: {e}")
        # Return a proper error response for monitoring
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}