################################################################################
# S3 Buckets
################################################################################

# Resource to generate a unique, readable suffix for our resources
resource "random_pet" "suffix" {
  length = 2
}

module "s3_raw_data" {
  source      = "../../modules/s3"
  # Use the random suffix to create a unique bucket name
  bucket_name = "csv-raw-data-${random_pet.suffix.id}"
  tags = {
    "Zone" = "Raw"
  }
}

module "s3_processed_data" {
  source      = "../../modules/s3"
  bucket_name = "csv-processed-data-${random_pet.suffix.id}"
  tags = {
    "Zone" = "Processed"
  }
}

module "s3_final_data" {
  source      = "../../modules/s3"
  bucket_name = "csv-final-data-${random_pet.suffix.id}"
  tags = {
    "Zone" = "Final"
  }
}

################################################################################
# IAM Policies and Roles
################################################################################

# --- Policy for Lambda Preprocessing Function ---
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    actions = [
      "s3:GetObject"
    ]
    resources = ["arn:aws:s3:::${module.s3_raw_data.bucket_id}/*"]
  }

  statement {
    actions = [
      "s3:PutObject"
    ]
    resources = ["arn:aws:s3:::${module.s3_processed_data.bucket_id}/*"]
  }
}

# --- Assume Role Policy for Lambda ---
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# --- Assume Role Policy for Glue ---
data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

# --- Create the Lambda Role ---
module "iam_lambda_role" {
  source                  = "../../modules/iam"
  role_name               = "CSV-Preprocessing-Lambda-Role-Dev"
  assume_role_policy_json = data.aws_iam_policy_document.lambda_assume_role.json
  create_custom_policy    = true 
  custom_policy_json      = data.aws_iam_policy_document.lambda_policy.json
}

# --- Create the Glue Role ---
module "iam_glue_role" {
  source                  = "../../modules/iam"
  role_name               = "CSV-ETL-Glue-Role-Dev"
  assume_role_policy_json = data.aws_iam_policy_document.glue_assume_role.json
  managed_policy_arns     = ["arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"]
  # Note: The AWSGlueServiceRole managed policy provides the necessary permissions 
  # for Glue jobs, including S3 access and CloudWatch logging.
}

################################################################################
# Lambda Preprocessing Function
################################################################################

module "lambda_preprocessing" {
  source           = "../../modules/lambda"
  function_name    = "CSV-Preprocessing-Function-Dev"
  source_code_zip_path = "../../build/lambda_function.zip" 
  iam_role_arn     = module.iam_lambda_role.role_arn
  trigger_bucket_id = module.s3_raw_data.bucket_id
  
  environment_variables = {
    DESTINATION_BUCKET = module.s3_processed_data.bucket_id
  }
}


################################################################################
# AWS Glue for ETL
################################################################################

# Resource to upload the Glue script to the 'processed' bucket.
# A dedicated bucket for scripts is also a good practice.
resource "aws_s3_object" "glue_script" {
  bucket = module.s3_processed_data.bucket_id
  key    = "glue_scripts/job.py"
  source = "../../src/glue_etl_job/job.py"
  etag   = filemd5("../../src/glue_etl_job/job.py")
}

module "glue_etl" {
  source                 = "../../modules/glue"
  crawler_name           = "CSV-Data-Crawler-Dev"
  crawler_s3_target_path = module.s3_processed_data.bucket_id
  crawler_iam_role_arn   = module.iam_glue_role.role_arn
  database_name          = "csv_data_pipeline_db_dev"
  
  job_name               = "CSV-to-Parquet-ETL-Job-Dev"
  job_iam_role_arn       = module.iam_glue_role.role_arn
  job_script_s3_path     = "${module.s3_processed_data.bucket_id}/${aws_s3_object.glue_script.key}"
}