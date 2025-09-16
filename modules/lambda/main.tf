
# Create the Lambda function
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.iam_role_arn
  handler       = "main.lambda_handler"
  runtime       = "python3.9"

  filename         = var.source_code_zip_path
  source_code_hash = filebase64sha256(var.source_code_zip_path)

  timeout     = 30
  memory_size = 256
  
  environment {
    variables = var.environment_variables
  }
}

# Grant S3 permission to invoke the Lambda function
resource "aws_lambda_permission" "allow_s3" {
  count         = var.create_s3_trigger ? 1 : 0 # Control with the flag
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.trigger_bucket_id}"
}

# Create the S3 bucket notification that triggers the function
resource "aws_s3_bucket_notification" "bucket_notification" {
  count  = var.create_s3_trigger ? 1 : 0 # Control with the flag
  bucket = var.trigger_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.this.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

# ... (existing resources)

# Grant API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "api_gateway_permission" {
  count         = var.create_api_gateway_permission ? 1 : 0
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*/*"
}