module "screenshot_url_lambda" {
    source = "./modules/lambda"
    zip_path = module.screenshot_url_zip_archive.output_path
    function_name = "test-funky-qr-screenshot-url"
    role_arn = module.screenshot_url_role.lambda_role_arn
    lambda_handler_name = "screenshot_url.screenshot_url"
    layer_arns = ["arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p38-requests:18"]
    existing_bucket_name = "s2h-raw"
}

module "screenshot_url_zip_archive" {
    source = "./modules/archive"
    source_file = "${path.root}/lambda_code/screenshot_url.py"
    output_path = "${path.root}/modules/archive/screenshot_url.zip"
}

module "screenshot_url_role" {
    source = "./modules/iam"
    lambda_role_name = "test-screenshot-url-lambda-role"
    lambda_policy_name = "test-screenshot-url-lambda-role-policy"
}