variable "state_machine_name" {
  description = "The name of the Step Functions state machine."
  type        = string
}

variable "state_machine_role_arn" {
  description = "The ARN of the IAM role for the state machine."
  type        = string
}

variable "glue_crawler_name" {
  description = "The name of the Glue crawler to run."
  type        = string
}

variable "glue_job_name" {
  description = "The name of the Glue job to run."
  type        = string
}

# --- NEW VARIABLES REQUIRED FOR THE FIX ---
variable "glue_database_name" {
  description = "The name of the Glue database the crawler writes to."
  type        = string
}

variable "glue_crawler_table_name" {
  description = "The name of the table created by the Glue crawler."
  type        = string
}

variable "final_bucket_name" {
  description = "The name of the S3 bucket for the final, transformed data."
  type        = string
}