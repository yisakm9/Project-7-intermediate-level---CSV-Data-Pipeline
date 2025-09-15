output "function_name" {
  description = "The name of the created Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "The ARN of the created Lambda function."
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "The ARN to be used for invoking this function from other services."
  value       = aws_lambda_function.this.invoke_arn
}