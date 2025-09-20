resource "aws_sfn_state_machine" "this" {
  name     = var.state_machine_name
  role_arn = var.state_machine_role_arn

  definition = jsonencode({
    Comment = "A state machine to orchestrate the Glue Crawler and ETL Job.",
    StartAt = "RunGlueCrawler",
    States = {
      RunGlueCrawler = {
        Type        = "Task",
        # --- THIS IS THE FIX ---
        # Use the .sync integration to wait for the crawler to complete
        Resource    = "arn:aws:states:::glue:startCrawler.sync",
        Parameters = {
          Name = var.glue_crawler_name
        },
        Next = "RunGlueJob"
      },
      RunGlueJob = {
        Type        = "Task",
        # Use the .sync integration to wait for the job to complete
        Resource    = "arn:aws:states:::glue:startJobRun.sync",
        Parameters = {
          JobName = var.glue_job_name
        },
        End = true
      }
    }
  })
}