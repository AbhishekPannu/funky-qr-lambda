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
  trigger_bucket = "s2h-raw"
}

module "screenshot_url" {
  source         = "./modules/lambda_handler"
  function_name  = "test-funky-qr-screenshot-url"
  source_dir     = "./lambda_code/screenshot_url.py"
  trigger_bucket = "s2h-raw"
}

module "call_databricks_api" {
  source         = "./modules/lambda_handler"
  function_name  = "test-funky-qr-call-databricks-api"
  source_dir     = "./lambda_code/call_databricks_api.py"
  trigger_bucket = "s2h-raw"
}