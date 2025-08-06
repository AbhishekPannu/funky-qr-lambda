module "extract_url_lambda" {
  source               = "./modules/lambda"
  zip_path             = module.call_databricks_api_zip_archive.output_path
  function_name        = "test-funky-qr-call_databricks_api"
  role_arn             = module.call_databricks_api_role.lambda_role_arn
  lambda_handler_name  = "call_databricks_api.call_databricks_api"
  layer_arns           = ["arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p38-requests:18"]
  existing_bucket_name = "s2h-raw"
}

module "call_databricks_api_zip_archive" {
  source      = "./modules/archive"
  source_file = "${path.root}/lambda_code/call_databricks_api.py"
  output_path = "call_databricks_api.zip"
}

module "call_databricks_api_role" {
  source             = "./modules/iam"
  lambda_role_name   = "test-call_databricks_api-lambda-role"
  lambda_policy_name = "test-call_databricks_api-lambda-role-policy"
}