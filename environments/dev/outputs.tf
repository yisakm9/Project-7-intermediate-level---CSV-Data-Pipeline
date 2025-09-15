output "raw_bucket_id" {
  description = "ID of the raw data S3 bucket."
  value       = module.s3_raw_data.bucket_id
}

output "processed_bucket_id" {
  description = "ID of the processed data S3 bucket."
  value       = module.s3_processed_data.bucket_id
}

output "final_bucket_id" {
  description = "ID of the final data S3 bucket."
  value       = module.s3_final_data.bucket_id
}


output "lambda_role_arn" {
  description = "ARN of the IAM role for the preprocessing Lambda function."
  value       = module.iam_lambda_role.role_arn
}

output "glue_role_arn" {
  description = "ARN of the IAM role for the Glue ETL job."
  value       = module.iam_glue_role.role_arn
}

output "lambda_function_name" {
  description = "The name of the preprocessing Lambda function."
  value       = module.lambda_preprocessing.function_name
}

output "website_url" {
  description = "The URL for the deployed frontend application."
  value       = "https://${module.frontend.cloudfront_domain_name}"
}

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution for the frontend."
  value       = module.frontend.cloudfront_distribution_id
}