terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 4.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
}

module "lambda_extract_url" {
    source = "./modules/lambda"
    zip_path = module.zip_archive.output_path
    function_name = "test-funky-qr-extract-url"
    role_name = module.iam_for_url_extraction.lambda_role
    lambda_handler_name = "extract_url.extract_url"
    layer_arns = ["arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p38-requests:18"]
    existing_bucket_name = "s2h_raw"
}

module "zip_archive" {
    source = "./modules/archive"
    source_file = "extract_url.py"
    output_path = "extract_url.zip"
}

module "backend_state_file" {
    source = "./modules/backend"
    bucket_name = "funky-qr-lambda-backend-s3"
    dynamodb_table = "funky-qr-state-locking-db"
    state_file_path = "lambda/terraform.tfstate"
    region_name = "us-east-1"
}

module "iam_for_url_extraction" {
    source = "./modules/iam"
    lambda_role_name = "test-funky-qr-lambda-role"
    lambda_policy_name = "test-funky-qr-lambda-role-policy"
}