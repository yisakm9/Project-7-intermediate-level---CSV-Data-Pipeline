# Create the Glue Data Catalog database
resource "aws_glue_catalog_database" "this" {
  name = var.database_name
}

# Instead of a crawler, we explicitly define the final table's schema.
resource "aws_glue_catalog_table" "final_data_table" {
  name          = var.final_data_table_name
  database_name = aws_glue_catalog_database.this.name

  storage_descriptor {
    location      = "s3://${var.final_data_s3_path}/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "ParquetHiveSerDe"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }

    # --- THIS IS THE FIX ---
    # Define the exact, clean schema that our final Glue job produces.
    columns {
      name    = "item_type"
      type    = "string"
    }
    columns {
      name    = "aggregated_revenue"
      type    = "string"
    }
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