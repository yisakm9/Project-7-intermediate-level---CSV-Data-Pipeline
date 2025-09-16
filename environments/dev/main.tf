################################################################################
# S3 Buckets
################################################################################

# Resource to generate a unique, readable suffix for our resources
resource "random_pet" "suffix" {
  length = 2
}

module "s3_raw_data" {
  source      = "../../modules/s3"
  bucket_name = "csv-raw-data-${random_pet.suffix.id}"
  tags        = { "Zone" = "Raw" }
}

module "s3_processed_data" {
  source      = "../../modules/s3"
  bucket_name = "csv-processed-data-${random_pet.suffix.id}"
  tags        = { "Zone" = "Processed" }
}

module "s3_final_data" {
  source      = "../../modules/s3"
  bucket_name = "csv-final-data-${random_pet.suffix.id}"
  tags        = { "Zone" = "Final" }
}

################################################################################
# IAM Policies and Roles
################################################################################

# --- Assume Role Policies ---
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

# --- Policy for Preprocessing Lambda ---
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_raw_data.bucket_arn}/*"]
  }
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${module.s3_processed_data.bucket_arn}/*"]
  }
}

# --- Policy for Glue ETL Job ---
data "aws_iam_policy_document" "glue_s3_policy" {
  statement {
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      module.s3_processed_data.bucket_arn,
      "${module.s3_processed_data.bucket_arn}/*",
      module.s3_final_data.bucket_arn,
      "${module.s3_final_data.bucket_arn}/*",
    ]
  }
  statement {
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${module.s3_final_data.bucket_arn}/*"]
  }
}

# --- Create IAM Roles ---
module "iam_lambda_role" {
  source                  = "../../modules/iam"
  role_name               = "CSV-Preprocessing-Lambda-Role-Dev"
  assume_role_policy_json = data.aws_iam_policy_document.lambda_assume_role.json
  create_custom_policy    = true
  custom_policy_json      = data.aws_iam_policy_document.lambda_policy.json
}

module "iam_glue_role" {
  source                  = "../../modules/iam"
  role_name               = "CSV-ETL-Glue-Role-Dev"
  assume_role_policy_json = data.aws_iam_policy_document.glue_assume_role.json
  managed_policy_arns     = ["arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"]
  create_custom_policy    = true
  custom_policy_json      = data.aws_iam_policy_document.glue_s3_policy.json
}

################################################################################
# Lambda Preprocessing Function
################################################################################

module "lambda_preprocessing" {
  source               = "../../modules/lambda"
  function_name        = "CSV-Preprocessing-Function-Dev"
  source_code_zip_path = "../../build/lambda_function.zip"
  iam_role_arn         = module.iam_lambda_role.role_arn
  create_s3_trigger    = true
  trigger_bucket_id    = module.s3_raw_data.bucket_id
  environment_variables = {
    DESTINATION_BUCKET = module.s3_processed_data.bucket_id
  }
}

################################################################################
# AWS Glue for ETL
################################################################################

resource "aws_s3_object" "glue_script" {
  bucket = module.s3_processed_data.bucket_id
  key    = "glue_scripts/job.py"
  source = "../../src/glue_etl_job/job.py"
  etag   = filemd5("../../src/glue_etl_job/job.py")
}

module "glue_etl" {
  source                       = "../../modules/glue"
  crawler_name                 = "CSV-Data-Crawler-Dev"
  crawler_s3_target_path       = module.s3_final_data.bucket_id
  crawler_iam_role_arn         = module.iam_glue_role.role_arn
  database_name                = "csv_data_pipeline_db_dev"
  job_name                     = "CSV-to-Parquet-ETL-Job-Dev"
  job_iam_role_arn             = module.iam_glue_role.role_arn
  job_script_s3_path           = "${module.s3_processed_data.bucket_id}/${aws_s3_object.glue_script.key}"
  job_default_args_input_path  = module.s3_processed_data.bucket_id
  job_default_args_output_path = module.s3_final_data.bucket_id
}

################################################################################
# API Layer & Frontend
# NOTE: The order is important here to avoid dependency cycles.
# 1. Frontend (creates CloudFront ARN)
# 2. API Lambda (creates Lambda ARN)
# 3. API Gateway (uses Lambda ARN)
# 4. API Gateway Policy (connects API Gateway and Frontend)
################################################################################

# --- Frontend Layer  (S3, CloudFront) ---
module "frontend" {
  source                 = "../../modules/frontend"
  bucket_name            = "csv-pipeline-ui-${random_pet.suffix.id}"
  api_gateway_invoke_url = module.api_gateway.invoke_url
  frontend_source_path   = "../../src/frontend"
}

# --- IAM Role for the API Lambda ---
data "aws_iam_policy_document" "api_lambda_policy" {
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    actions   = ["athena:StartQueryExecution", "athena:GetQueryExecution", "athena:GetQueryResults", "glue:GetDatabase", "glue:GetTable", "glue:GetPartitions"]
    resources = ["*"]
  }
  statement {
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [
      module.s3_final_data.bucket_arn,
      "${module.s3_final_data.bucket_arn}/*",
      module.frontend.frontend_bucket_arn,
    ]
  }
  statement {
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${module.frontend.frontend_bucket_arn}/athena-results/*"]
  }
  statement {
    actions   = ["s3:GetBucketLocation"]
    resources = [module.frontend.frontend_bucket_arn]
  }
}

module "iam_api_lambda_role" {
  source                  = "../../modules/iam"
  role_name               = "CSV-API-Lambda-Role-Dev"
  assume_role_policy_json = data.aws_iam_policy_document.lambda_assume_role.json
  create_custom_policy    = true
  custom_policy_json      = data.aws_iam_policy_document.api_lambda_policy.json
}

# --- API Lambda Function ---
module "api_lambda" {
  source               = "../../modules/lambda"
  function_name        = "CSV-API-Function-Dev"
  source_code_zip_path = "../../build/api_lambda.zip"
  iam_role_arn         = module.iam_api_lambda_role.role_arn
  environment_variables = {
    ATHENA_DATABASE       = module.glue_etl.database_name
    ATHENA_TABLE          = module.glue_etl.table_name
    ATHENA_OUTPUT_S3_PATH = "s3://${module.frontend.frontend_bucket_id}/athena-results/"
  }
  create_api_gateway_permission = true
  api_gateway_execution_arn     = module.api_gateway.execution_arn
  create_s3_trigger             = false
}

#  API Gateway
module "api_gateway" {
  source            = "../../modules/apigateway"
  api_name          = "CSV-Data-API-${random_pet.suffix.id}"
  lambda_invoke_arn = module.api_lambda.invoke_arn
}


# --- API Gateway Policy  (Connects Frontend and API Gateway) ---
resource "aws_api_gateway_rest_api_policy" "this" {
  rest_api_id = module.api_gateway.rest_api_id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "cloudfront.amazonaws.com" },
        Action    = "execute-api:Invoke",
        Resource  = "${module.api_gateway.execution_arn}/*/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.frontend.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}