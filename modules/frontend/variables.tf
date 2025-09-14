variable "bucket_name" {
  description = "Name for the S3 bucket hosting the UI."
  type        = string
}

variable "api_gateway_invoke_url" {
  description = "The invoke URL of the API Gateway stage for the API origin."
  type        = string
}

variable "frontend_source_path" {
  description = "Path to the frontend source files."
  type        = string
}