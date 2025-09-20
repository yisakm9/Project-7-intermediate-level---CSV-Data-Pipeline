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

variable "final_data_table_name" {
  description = "The name for the final data table in the Glue Catalog."
  type        = string
}

variable "final_data_s3_path" {
  description = "The S3 path where the final Parquet data is stored."
  type        = string
}