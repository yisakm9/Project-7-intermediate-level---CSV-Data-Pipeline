output "invoke_url" {
  description = "The invoke URL for the deployment stage of the API."
  # Use the invoke_url from the new stage resource
  value       = aws_api_gateway_stage.this.invoke_url
}

output "execution_arn" {
  description = "The execution ARN of the API to be used in Lambda permissions."
  value       = aws_api_gateway_rest_api.this.execution_arn
}

output "rest_api_id" {
  description = "The ID of the REST API."
  value       = aws_api_gateway_rest_api.this.id
}
