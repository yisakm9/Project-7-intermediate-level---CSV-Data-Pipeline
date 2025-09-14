# S3 Bucket for UI
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "frontend_bucket_pab" {
  bucket                  = aws_s3_bucket.frontend_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront OAC for S3
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "OAC for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id                = "S3-UI-Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  origin {
    domain_name = replace(trimsuffix(var.api_gateway_invoke_url, "/"), "https://", "")
    origin_id   = "API-Gateway-Origin"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-UI-Origin"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/get-sales-data"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "API-Gateway-Origin"
    viewer_protocol_policy = "https-only"
    compress               = true
    # Do not cache API responses
    default_ttl = 0
    min_ttl     = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# S3 Bucket Policy
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend_bucket.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

# Upload the index.html file
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = "index.html"
  source       = "${var.frontend_source_path}/index.html"
  etag         = filemd5("${var.frontend_source_path}/index.html")
  content_type = "text/html"
}

# Generate and upload the config.js file directly to S3
resource "aws_s3_object" "config_js" {
  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = "config.js"
  
  # Generate content directly in memory instead of creating a local file
  content      = "const API_ENDPOINT = 'https://${aws_cloudfront_distribution.s3_distribution.domain_name}';"
  
  # Use md5() on the content string, not filemd5() on a non-existent file path
  etag         = md5("const API_ENDPOINT = 'https://${aws_cloudfront_distribution.s3_distribution.domain_name}';")
  content_type = "application/javascript"
}