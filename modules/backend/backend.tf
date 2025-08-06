terraform {
    backend "s3" {
        bucket = var.bucket_name # "s2h-raw"
        key = var.state_file_path # "lambda/terraform.tfstate"
        region = var.region_name # "us-east-1"
        dynamodb_table = var.dynamodb_table_name
        encrypt = true
    }
}