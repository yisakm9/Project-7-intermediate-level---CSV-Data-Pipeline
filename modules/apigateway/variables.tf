variable "api_name" {
  description = "The name for the REST API."
  type        = string
}

variable "lambda_invoke_arn" {
  description = "The ARN of the Lambda function to be invoked by the API."
  type        = string
}