terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "extract_url" {
  source         = "./modules/lambda_handler"
  function_name  = "test-funky-qr-extract-url"
  source_dir     = "./lambda_code/extract_url.py"
  trigger_bucket = "funkyqrstoragebucketb02b5-dev"
  filter_prefix  = "public/qr-codes/"
  trigger_type   = "s3"
}

module "screenshot_url" {
  source              = "./modules/lambda_handler"
  function_name       = "test-funky-qr-screenshot-url"
  source_dir          = "./lambda_code/screenshot_url.py"
  trigger_type        = "dynamodb"
  dynamodb_table_name = "DecodedURLs"
}

module "databricks_api" {
  source         = "./modules/lambda_handler"
  function_name  = "test-funky-qr-call-databricks-api"
  source_dir     = "./lambda_code/call_databricks_api.py"
  trigger_bucket = "funkyqrstoragebucketb02b5-dev"
  filter_prefix  = "website_screenshot/"
  trigger_type   = "s3"
}