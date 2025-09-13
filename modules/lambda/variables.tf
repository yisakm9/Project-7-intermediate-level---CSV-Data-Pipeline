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
}
variable "environment_variables" {
description = "A map of environment variables for the Lambda function."
type = map(string)
default = {}
}