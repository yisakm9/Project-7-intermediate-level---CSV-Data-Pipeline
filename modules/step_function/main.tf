resource "aws_sfn_state_machine" "this" {
  name     = var.state_machine_name
  role_arn = var.state_machine_role_arn

  definition = jsonencode({
    Comment = "Orchestrates the Glue ETL Job.",
    StartAt = "StartGlueJob",
    States = {
      StartGlueJob = {
        Type = "Task",
        Resource = "arn:aws:states:::glue:startJobRun.sync",
        Parameters = {
          JobName = var.glue_job_name,
          "Arguments" = {
            "--input_path"  = "s3://${var.processed_bucket_name}/",
            "--output_path" = "s3://${var.final_bucket_name}/"
          }
        },
        End = true
      }
    }
  })
}