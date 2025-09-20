resource "aws_sfn_state_machine" "this" {
  name     = var.state_machine_name
  role_arn = var.state_machine_role_arn

  definition = jsonencode({
    Comment = "Orchestrates Glue Crawler and ETL Job, handling concurrency.",
    StartAt = "GetInitialCrawlerStatus",
    States = {
      GetInitialCrawlerStatus = {
        Type = "Task",
        Resource = "arn:aws:states:::aws-sdk:glue:getCrawler",
        Parameters = {
          Name = var.glue_crawler_name
        },
        ResultPath = "$.CrawlerStatus",
        Next       = "IsCrawlerBusy"
      },
      IsCrawlerBusy = {
        Type = "Choice",
        Choices = [
          {
            Or = [
              {
                Variable   = "$.CrawlerStatus.Crawler.State",
                StringEquals = "RUNNING"
              },
              {
                Variable   = "$.CrawlerStatus.Crawler.State",
                StringEquals = "STOPPING"
              }
            ],
            Next = "WaitForCrawler"
          }
        ],
        Default = "StartCrawlerExecution"
      },
      WaitForCrawler = {
        Type    = "Wait",
        Seconds = 30,
        Next    = "GetInitialCrawlerStatus"
      },
      StartCrawlerExecution = {
        Type = "Task",
        Resource = "arn:aws:states:::aws-sdk:glue:startCrawler",
        Parameters = {
          Name = var.glue_crawler_name
        },
        Catch = [{
          ErrorEquals = ["States.ALL"],
          Next        = "CrawlerFailed"
        }],
        Next = "MonitorCrawler"
      },
      MonitorCrawler = {
        Type = "Task",
        Resource = "arn:aws:states:::aws-sdk:glue:getCrawler",
        Parameters = {
          Name = var.glue_crawler_name
        },
        ResultPath = "$.CrawlerStatus",
        Next       = "IsCrawlerFinished"
      },
      IsCrawlerFinished = {
        Type = "Choice",
        Choices = [
          {
            Variable   = "$.CrawlerStatus.Crawler.State",
            StringEquals = "READY",
            Next       = "StartGlueJob"
          }
        ],
        Default = "WaitForCrawlerToFinish"
      },
      WaitForCrawlerToFinish = {
        Type    = "Wait",
        Seconds = 30,
        Next    = "MonitorCrawler"
      },
      CrawlerFailed = {
        Type  = "Fail",
        Cause = "Glue Crawler failed or could not be started."
      },
      StartGlueJob = {
        Type = "Task",
        Resource = "arn:aws:states:::glue:startJobRun.sync",
        # --- THIS IS THE FIX ---
        # Pass all required arguments to the Glue Job script
        Parameters = {
          JobName = var.glue_job_name,
          "Arguments" = {
            "--input_database" = var.glue_database_name,
            "--input_table"    = var.glue_crawler_table_name,
            "--output_path"    = "s3://${var.final_bucket_name}/"
          }
        },
        End = true
      }
    }
  })
}