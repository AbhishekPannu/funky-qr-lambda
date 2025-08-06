data "archive_file" "lambda" {
    type = "zip"
    source_file = var.source_file
    output_path = var.output_path
}