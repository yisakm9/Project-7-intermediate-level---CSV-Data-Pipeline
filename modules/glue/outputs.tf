output "database_name" {
  description = "The name of the Glue Data Catalog database."
  value       = aws_glue_catalog_database.this.name
}

output "job_name" {
  description = "The name of the Glue ETL job."
  value       = aws_glue_job.this.name
}

output "final_data_table_name" {
  description = "The name of the declaratively created final data table."
  value       = aws_glue_catalog_table.final_data_table.name
}