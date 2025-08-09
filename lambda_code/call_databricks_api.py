import json
import boto3
import os
import requests

# Initialize clients outside the handler for performance.
cognito_client = boto3.client('cognito-idp')
secrets_manager = boto3.client('secretsmanager')

# Global cache for the token to improve performance on warm starts
DATABRICKS_TOKEN = None

def get_databricks_token(secret_arn):
    """Retrieves and caches the Databricks token from AWS Secrets Manager."""
    global DATABRICKS_TOKEN
    if DATABRICKS_TOKEN:
        return DATABRICKS_TOKEN
        
    print(f"Retrieving new Databricks token from secret: {secret_arn}")
    try:
        response = secrets_manager.get_secret_value(SecretId=secret_arn)
        # .strip() is crucial to remove any accidental whitespace from the secret
        DATABRICKS_TOKEN = response['SecretString'].strip()
        return DATABRICKS_TOKEN
    except Exception as e:
        print(f"ERROR: Could not retrieve secret from Secrets Manager: {e}")
        raise e

def lambda_handler(event, context):
    """
    This is the final production code. It is triggered by a DynamoDB Stream
    'MODIFY' event, gathers all user info, and starts a Databricks job.
    """
    print(f"Received event: {json.dumps(event)}")
    
    # Check for required environment variables at the start
    try:
        user_pool_id = os.environ['COGNITO_USER_POOL_ID']
        secret_arn = os.environ['DATABRICKS_TOKEN_SECRET_ARN']
        databricks_host = os.environ['DATABRICKS_HOST'].strip()
        databricks_job_id = os.environ['DATABRICKS_JOB_ID']
    except KeyError as e:
        print(f"FATAL CONFIGURATION ERROR: Missing environment variable: {e}. Cannot proceed.")
        # We don't raise an error here because this is not a transient issue.
        # Returning success stops the broken invocation from being retried.
        return {'statusCode': 200, 'body': f'Configuration error: {e}'}

    try:
        for record in event.get("Records", []):
            if record.get("eventName") != "MODIFY":
                continue

            new_image = record.get("dynamodb", {}).get("NewImage")
            if not new_image:
                continue

            # --- 1. Extract primary data from the DynamoDB record ---
            screenshot_url = new_image.get("screenshot_url", {}).get("S")
            user_id = new_image.get("user_id", {}).get("S")
            decoded_url = new_image.get("decoded_url", {}).get("S")
            
            if not all([screenshot_url, user_id, decoded_url]):
                print(f"Skipping record due to missing required data: {new_image}")
                continue

            print(f"Processing record for user_id: {user_id}")
            
            # --- 2. Get the user's full profile from Cognito ---
            print("Fetching user profile from Cognito...")
            cognito_response = cognito_client.admin_get_user(
                UserPoolId=user_pool_id,
                Username=user_id
            )
            user_attributes = {attr['Name']: attr['Value'] for attr in cognito_response['UserAttributes']}
            print("Successfully fetched user profile.")
            
            # --- 3. Prepare the complete payload for the Databricks job ---
            databricks_params = {
                'screenshot_url': screenshot_url,
                'decoded_qr_url': decoded_url,
                'user_id': user_id,
                'user_name': user_attributes.get('name'),
                'user_email': user_attributes.get('email'),
                'user_gender': user_attributes.get('gender')
            }
            
            # --- 4. Get credentials and trigger the Databricks job ---
            databricks_token = get_databricks_token(secret_arn)
            api_url = f"https://{databricks_host}/api/2.0/jobs/run-now"
            headers = {'Authorization': f'Bearer {databricks_token}', 'Content-Type': 'application/json'}
            payload = {"job_id": int(databricks_job_id), "notebook_params": databricks_params}

            print(f"Triggering Databricks job with payload: {json.dumps(payload)}")
            response = requests.post(api_url, headers=headers, json=payload, timeout=30)
            response.raise_for_status() # Raise an exception for non-2xx status codes

            print(f"Successfully triggered Databricks job. Run ID: {response.json().get('run_id')}")

        return {'statusCode': 200, 'body': 'Successfully processed all records.'}

    except Exception as e:
        print(f"FATAL ERROR during execution: {e}")
        # Re-raise the exception. This signals to AWS Lambda that the invocation
        # failed, which will allow for automatic retries based on your trigger's configuration.
        # This is the correct behavior for transient errors (like a network blip).
        raise e