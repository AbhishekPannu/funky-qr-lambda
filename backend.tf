terraform {
    backend "s3" {
        bucket = "funky-qr-lambda-backend-s3"
        key = "lambda/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "funky-qr-state-locking-db"
        encrypt = true
    }
}