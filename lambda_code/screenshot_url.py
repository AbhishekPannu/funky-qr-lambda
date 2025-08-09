import boto3
import requests
import os
import uuid
from datetime import datetime

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb", region_name="us-east-1")

# Get your API key from environment variable
APIFLASH_API_KEY = os.environ.get("APIFLASH_API_KEY")

# S3 config
S3_BUCKET_NAME = "funkyqrstoragebucketb02b5-dev"
S3_FOLDER = "website_screenshot"

def take_screenshot(url):
    params = {
        "access_key": APIFLASH_API_KEY,
        "url": url,
        "full_page": "true",
        "format": "png",
        "response_type": "image"
    }
    print(f"Calling apiflash with: {url}")
    response = requests.get("https://api.apiflash.com/v1/urltoimage", params=params)

    if response.status_code == 200:
        return response.content
    else:
        raise Exception(f"ApiFlash failed: {response.status_code}, {response.text}")

def upload_to_s3(image_bytes, url):
    filename = f"{uuid.uuid4()}.png"
    s3_key = f"{S3_FOLDER}/{filename}"

    s3.put_object(
        Bucket=S3_BUCKET_NAME,
        Key=s3_key,
        Body=image_bytes,
        ContentType="image/png",
        Metadata={"source-url": url}
    )

    return f"https://{S3_BUCKET_NAME}.s3.amazonaws.com/{s3_key}"

def lambda_handler(event, context):
    try:
        print("EVENT:", event)

        for record in event.get("Records", []):
            if record["eventName"] != "INSERT":
                continue

            new_image = record["dynamodb"].get("NewImage", {})
            if not new_image:
                continue

            screenshot_url = new_image.get("screenshot_url", {}).get("S")
            if screenshot_url:
                print(f"Screenshot already exists at {screenshot_url}, skipping.")
                continue

            url = new_image["decoded_url"]["S"]
            user_id = new_image.get("user_id", {}).get("S", "unknown")
            timestamp = new_image.get("scan_timestamp", {}).get("S", datetime.utcnow().isoformat())

            print(f"Taking screenshot of URL: {url}")
            screenshot_bytes = take_screenshot(url)
            s3_url = upload_to_s3(screenshot_bytes, url)

            print(f"Uploaded screenshot to: {s3_url}")

            # (Optional) Update DynamoDB with screenshot URL or status
            table = dynamodb.Table("DecodedURLs")
            item_id = new_image["id"]["S"]
            table.update_item(
                Key={"id": item_id},
                UpdateExpression="SET #st = :status, screenshot_url = :url",
                ExpressionAttributeNames={"#st": "status"},
                ExpressionAttributeValues={
                    ":status": "screenshot_taken",
                    ":url": s3_url
                }
            )
            print("DynamoDB updated with screenshot URL")

        return {"statusCode": 200, "body": "Screenshot captured"}

    except Exception as e:
        print("ERROR:", str(e))
        return {"statusCode": 500, "body": str(e)}
