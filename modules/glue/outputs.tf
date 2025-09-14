output "crawler_name" {
  value = aws_glue_crawler.this.name
}

output "job_name" {
  value = aws_glue_job.this.name
}

output "table_name" {
  description = "The name of the table created by the Glue crawler."
  # The crawler names the table after the S3 path, replacing '/' with '_'
  value = replace(var.crawler_s3_target_path, "-", "_") 
}

output "database_name" {
    description = "The name of the Glue database created."
    value = aws_glue_catalog_database.this.name
}