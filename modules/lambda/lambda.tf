resource "aws_lambda_function" "this" {
  filename         = var.zip_path
  function_name    = var.function_name
  role             = var.role_arn
  handler          = var.lambda_handler_name
  source_code_hash = filebase64sha256(var.zip_path)
  layers           = var.layer_arns
  runtime          = var.runtime_version
}

data "aws_s3_bucket" "existing" {
  count         = var.trigger_type == "s3" ? 1 : 0
  bucket = var.trigger_bucket
}

resource "aws_lambda_permission" "allow_bucket" {
  count         = var.trigger_type == "s3" ? 1 : 0
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.existing.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count  = var.trigger_type == "s3" ? 1 : 0
  bucket = data.aws_s3_bucket.existing.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.this.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = var.filter_prefix
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

data "aws_dynamodb_table" "decoded_urls" {
  count = var.trigger_type == "dynamodb" ? 1 : 0
  name  = var.dynamodb_table_name
}

resource "aws_lambda_event_source_mapping" "ddb_trigger" {
  count             = var.trigger_type == "dynamodb" ? 1 : 0
  event_source_arn  = data.aws_dynamodb_table.decoded_urls[0].stream_arn
  function_name     = aws_lambda_function.this.arn
  starting_position = "LATEST"
}