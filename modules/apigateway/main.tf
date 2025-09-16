
# Create a resource within the API (e.g., /get-sales-data)
resource "aws_api_gateway_resource" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "get-sales-data"
}

# Define the GET method for the resource
resource "aws_api_gateway_method" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.this.id
  http_method   = "GET"
  authorization = "NONE"
}

# Create the integration between the GET method and the Lambda function
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.this.id
  http_method             = aws_api_gateway_method.this.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# --- CORRECTED DEPLOYMENT AND STAGE ---

# Create a deployment resource. The lifecycle block is key.
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  # This tells Terraform that this deployment should be replaced
  # whenever the API's configuration changes.
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.this.path,
      aws_api_gateway_method.this.http_method,
      aws_api_gateway_integration.lambda.uri,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create the stage and point it to the deployment
resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "v1"
}