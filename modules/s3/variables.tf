variable "bucket_name" {
  description = "The name of the S3 bucket."
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}

variable "allowed_cors_origins" {
  description = "A list of origins that are allowed to make CORS requests."
  type        = list(string)
  default     = []
}