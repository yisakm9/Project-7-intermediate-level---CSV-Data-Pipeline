output "invoke_url" {
  description = "The invoke URL for the default stage of the API."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "execution_arn" {
  description = "The execution ARN of the API to be used in Lambda permissions."
  value       = aws_apigatewayv2_api.http_api.execution_arn
}