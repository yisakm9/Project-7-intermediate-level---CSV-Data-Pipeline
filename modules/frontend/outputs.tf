output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution."
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "frontend_bucket_id" {
  description = "The ID of the S3 bucket for the frontend UI."
  value       = aws_s3_bucket.frontend_bucket.id
}

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.s3_distribution.id
}

output "cloudfront_distribution_arn" {
  description = "The ARN of the CloudFront distribution."
  value       = aws_cloudfront_distribution.s3_distribution.arn
}
output "frontend_bucket_arn" {
  description = "The ARN of the S3 bucket for the frontend UI."
  value       = aws_s3_bucket.frontend_bucket.arn
}