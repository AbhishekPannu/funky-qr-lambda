module "extract_url_lambda" {
  source               = "./modules/lambda"
  zip_path             = module.extract_url_zip_archive.output_path
  function_name        = "test-funky-qr-extract-url"
  role_arn             = module.extract_url_role.lambda_role_arn
  lambda_handler_name  = "extract_url.extract_url"
  layer_arns           = ["arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p38-requests:18"]
  existing_bucket_name = "test-extract-url-bucket"
}

module "extract_url_zip_archive" {
  source      = "./modules/archive"
  source_file = "${path.root}/lambda_code/extract_url.py"
  output_path = "${path.root}/modules/archive/extract_url.zip"
}

module "extract_url_role" {
  source             = "./modules/iam"
  lambda_role_name   = "test-extract-url-lambda-role"
  lambda_policy_name = "test-extract-url-lambda-role-policy"
}