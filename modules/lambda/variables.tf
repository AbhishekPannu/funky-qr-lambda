variable "zip_path" {
    type = string
}

variable "function_name" {
    type = string
}

variable "role_arn" {
    type = string
}

variable "lambda_handler_name" {
    type = string
}

variable "layer_arns" {
    type  = list(string)
    default = []
}

variable "runtime_version" {
    type = string
    default = "python3.9"
}

variable "existing_bucket_name" {
    description = "Name of Existing bucket for trigger"
    type = string
}