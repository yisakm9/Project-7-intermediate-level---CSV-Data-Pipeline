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