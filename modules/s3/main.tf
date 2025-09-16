resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  # --- THIS IS THE FIX ---
  # Add a CORS rule block
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST", "GET"]
    allowed_origins = var.allowed_cors_origins
    expose_headers  = ["ETag"]
  }

  tags = merge(
    var.tags,
    {
      "ManagedBy" = "Terraform"
    }
  )
}
# Block all public access by default for security
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}