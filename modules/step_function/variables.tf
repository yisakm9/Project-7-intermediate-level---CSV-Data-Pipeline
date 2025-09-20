variable "state_machine_name" {
  description = "The name of the Step Functions state machine."
  type        = string
}

variable "state_machine_role_arn" {
  description = "The ARN of the IAM role for the state machine."
  type        = string
}

variable "glue_job_name" {
  description = "The name of the Glue job to run."
  type        = string
}

variable "processed_bucket_name" {
  description = "The name of the S3 bucket containing the processed data (job input)."
  type        = string
}

variable "final_bucket_name" {
  description = "The name of the S3 bucket for the final, transformed data (job output)."
  type        = string
}