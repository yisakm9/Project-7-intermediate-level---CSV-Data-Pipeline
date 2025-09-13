variable "crawler_name" {
  description = "Name of the Glue Crawler."
  type        = string
}

variable "crawler_s3_target_path" {
  description = "The S3 path for the crawler to scan."
  type        = string
}

variable "crawler_iam_role_arn" {
  description = "ARN of the IAM role for the Glue Crawler."
  type        = string
}

variable "database_name" {
  description = "Name of the Glue Data Catalog database."
  type        = string
}

variable "job_name" {
  description = "Name of the Glue ETL job."
  type        = string
}

variable "job_iam_role_arn" {
  description = "ARN of the IAM role for the Glue ETL job."
  type        = string
}

variable "job_script_s3_path" {
  description = "The S3 path to the Glue ETL job script."
  type        = string
}

variable "job_default_args_input_path" {
  description = "The default S3 path for the job's input data."
  type        = string
}

variable "job_default_args_output_path" {
  description = "The default S3 path for the job's output data."
  type        = string
}