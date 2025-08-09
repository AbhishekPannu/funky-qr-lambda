module "extract_url_lambda" {
  source               = "../lambda"
  zip_path             = module.zip_archive.output_path
  function_name        = var.function_name
  role_arn             = module.lambda_role.lambda_role_arn
  lambda_handler_name  = "${var.source_dir}.lambda"
  layer_arns           = ["arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p38-requests:18"]
  existing_bucket_name = var.trigger_bucket
}

module "zip_archive" {
  source      = "../archive"
  source_file = var.source_dir
}

module "lambda_role" {
  source        = "../iam"
  lambda_name   = var.function_name
  function_name = var.function_name
}