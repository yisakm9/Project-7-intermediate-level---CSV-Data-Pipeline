variable "function_name" {
description = "Name of the Lambda function."
type = string
}
variable "source_code_zip_path" {
  description = "The local path to the pre-packaged source code zip file."
  type        = string
}
variable "iam_role_arn" {
description = "ARN of the IAM role for the Lambda function."
type = string
}
variable "trigger_bucket_id" {
description = "The ID of the S3 bucket that will trigger this Lambda."
type = string
default = null
}
variable "environment_variables" {
description = "A map of environment variables for the Lambda function."
type = map(string)
default = {}
}

variable "create_api_gateway_permission" {
  description = "Boolean flag to control creation of API Gateway invocation permission."
  type        = bool
  default     = false
}

variable "api_gateway_execution_arn" {
  description = "The execution ARN from API Gateway, required if create_api_gateway_permission is true."
  type        = string
  default     = ""
}

variable "create_s3_trigger" {
  description = "Boolean flag to control creation of S3 bucket trigger."
  type        = bool
  default     = false
}



