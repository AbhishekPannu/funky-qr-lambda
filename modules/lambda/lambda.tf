resource "aws_lambda_function" "this" {
    filename = var.zip_path
    function_name = var.function_name
    role = var.role_name
    handler = var.lambda_handler_name
    source_code_hash = filebase64sha256(var.zip_path)
    layers = var.layer_arns
    runtime = var.runtime_version
}

data "aws_s3_bucket" "existing" {
  bucket = var.existing_bucket_name
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.existing.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.existing.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.this.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "AWSLogs/"
    filter_suffix       = ".log"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}