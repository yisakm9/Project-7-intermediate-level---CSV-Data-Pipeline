variable "role_name" {
  description = "The name for the IAM role."
  type        = string
}

variable "assume_role_policy_json" {
  description = "The JSON policy document that grants an entity permission to assume the role."
  type        = string
}

variable "create_custom_policy" {
  description = "A boolean flag to control whether a custom IAM policy is created and attached."
  type        = bool
  default     = false
}

variable "custom_policy_json" {
  description = "The custom IAM policy document in JSON format. Required if create_custom_policy is true."
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