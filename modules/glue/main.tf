# Create the Glue Data Catalog database
resource "aws_glue_catalog_database" "this" {
  name = var.database_name
}

# Create the Glue Crawler
resource "aws_glue_crawler" "this" {
  name          = var.crawler_name
  role          = var.crawler_iam_role_arn
  database_name = aws_glue_catalog_database.this.name

  s3_target {
    path = "s3://${var.crawler_s3_target_path}"
  }
}

# Create the Glue ETL Job
resource "aws_glue_job" "this" {
  name     = var.job_name
  role_arn = var.job_iam_role_arn
  command {
    script_location = "s3://${var.job_script_s3_path}"
    python_version  = "3"
  }
  glue_version = "4.0"
}