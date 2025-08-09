variable "function_name" {
  type        = string
  description = "Name of lambda function"
}

variable "source_dir" {
  type        = string
  description = "Source of Lambda python file"
}

variable "trigger_bucket" {
  type        = string
  description = "Name of bucket on which trigger notification is present"
  default     = ""
}

variable "function_arn" {
  type        = string
  description = "ARN of the Lambda function"
  default     = ""
}

variable "filter_prefix" {
  type        = string
  description = "Prefix of event trigger inside bucket"
  default     = ""
}

variable "trigger_type" {
  type = string
}

variable "dynamodb_table_name" {
  type    = string
  default = ""
}