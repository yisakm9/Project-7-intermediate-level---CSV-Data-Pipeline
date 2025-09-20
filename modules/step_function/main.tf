resource "aws_sfn_state_machine" "this" {
  name     = var.state_machine_name
  role_arn = var.state_machine_role_arn

  definition = jsonencode({
    Comment = "A state machine to orchestrate the Glue Crawler and ETL Job.",
    StartAt = "RunGlueCrawler",
    States = {
      RunGlueCrawler = {
        Type        = "Task",
        Resource    = "arn:aws:states:::glue:startCrawler",
        Parameters = {
          Name = var.glue_crawler_name
        },
        Next = "RunGlueJob"
      },
      RunGlueJob = {
        Type        = "Task",
        Resource    = "arn:aws:states:::glue:startJobRun.sync", # .sync waits for completion
        Parameters = {
          JobName = var.glue_job_name
        },
        End = true
      }
    }
  })
}