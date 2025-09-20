resource "aws_sfn_state_machine" "this" {
  name     = var.state_machine_name
  role_arn = var.state_machine_role_arn

  definition = jsonencode({
    Comment = "Orchestrates Glue Crawler and ETL Job",
    StartAt = "StartCrawlerExecution",
    States = {
      StartCrawlerExecution = {
        Type = "Task",
        # Use the AWS-SDK integration for starting the crawler
        Resource = "arn:aws:states:::aws-sdk:glue:startCrawler",
        Parameters = {
          Name = var.glue_crawler_name
        },
        # Catch errors if the crawler fails to start
        Catch = [{
          ErrorEquals = ["States.ALL"],
          Next        = "CrawlerFailed"
        }],
        Next = "Wait30Seconds"
      },
      Wait30Seconds = {
        Type    = "Wait",
        Seconds = 30,
        Next    = "GetCrawlerStatus"
      },
      GetCrawlerStatus = {
        Type = "Task",
        # Use the AWS-SDK integration to get the crawler's status
        Resource = "arn:aws:states:::aws-sdk:glue:getCrawler",
        Parameters = {
          Name = var.glue_crawler_name
        },
        # The result of this is a JSON object, we need the state from it
        ResultPath = "$.CrawlerStatus",
        Next       = "IsCrawlerReady"
      },
      IsCrawlerReady = {
        Type = "Choice",
        Choices = [
          {
            # Check the state from the previous step's output
            Variable   = "$.CrawlerStatus.Crawler.State",
            StringEquals = "READY",
            Next       = "StartGlueJob"
          }
        ],
        # If it's still running, loop back to the wait state
        Default = "Wait30Seconds"
      },
      CrawlerFailed = {
        Type  = "Fail",
        Cause = "Glue Crawler failed or could not be started."
      },
      StartGlueJob = {
        Type = "Task",
        # The .sync integration IS correct for startJobRun
        Resource = "arn:aws:states:::glue:startJobRun.sync",
        Parameters = {
          JobName = var.glue_job_name
        },
        End = true
      }
    }
  })
}