output "crawler_name" {
  value = aws_glue_crawler.this.name
}

output "job_name" {
  value = aws_glue_job.this.name
}