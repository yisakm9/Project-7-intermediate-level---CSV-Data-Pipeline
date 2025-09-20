output "state_machine_arn" {
  description = "The ARN of the Step Functions state machine."
  # The .id attribute for this resource type returns the ARN
  value       = aws_sfn_state_machine.this.id
}