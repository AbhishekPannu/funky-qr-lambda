variable "function_name" {
  type        = string
  description = "Name of lambda function"
}

variable "trigger_bucket" {
  type = string
  default = ""
}