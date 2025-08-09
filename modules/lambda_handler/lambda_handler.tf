module "extract_url_lambda" {
  source               = "../lambda"
  zip_path             = module.zip_archive.output_path
  function_name        = var.function_name
  role_arn             = module.lambda_role.lambda_role_arn
  lambda_handler_name  = "${var.source_dir}.lambda"
  layer_arns           = ["arn:aws:lambda:us-east-1:770693421928:layer:Klayers-p38-requests:18"]
  trigger_bucket = var.trigger_bucket
  dynamodb_table_name = var.dynamodb_table_name
  filter_prefix = var.filter_prefix
  trigger_type = var.trigger_type
}

module "zip_archive" {
  source      = "../archive"
  source_file = var.source_dir
  function_name = var.function_name
}

module "lambda_role" {
  source        = "../iam"
  function_name   = var.function_name
  trigger_bucket = var.trigger_bucket
}