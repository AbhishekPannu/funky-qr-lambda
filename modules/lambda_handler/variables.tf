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
}

variable "function_arn" {
    type = string
}