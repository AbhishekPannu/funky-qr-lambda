module "extract_url_lambda" {
    source = "./modules/lambda"
    zip_path = module.extract_url_zip_archive.output_path
    function_name = "test-funky-qr-extract-url"
    role_arn = module.extract_url_role.lambda_role_arn
    lambda_handler_name = "extract_url.extract_url"
    layer_arns = ["arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p38-requests:18"]
    existing_bucket_name = "s2h-raw"
}

module "extract_url_zip_archive" {
    source = "./modules/archive"
    source_file = "lambda_code.extract_url.py"
    output_path = "extract_url.zip"
}

module "extract_url_role" {
    source = "./modules/iam"
    lambda_role_name = "test-extract-url-lambda-role"
    lambda_policy_name = "test-extract-url-lambda-role-policy"
}