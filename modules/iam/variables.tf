variable "role_name" {
  description = "The name for the IAM role."
  type        = string
}

variable "assume_role_policy_json" {
  description = "The JSON policy document that grants an entity permission to assume the role."
  type        = string
}

variable "custom_policy_json" {
  description = "A custom IAM policy document in JSON format to be attached to the role."
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "A list of ARNs for AWS-managed policies to attach to the role."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A map of tags to assign to the IAM role."
  type        = map(string)
  default     = {}
}