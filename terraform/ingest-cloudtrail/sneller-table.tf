# Table that holds all the ingested Cloudtrail log files
resource "sneller_table" "test" {
  # Enable this for production to avoid trashing your table
  # lifecycle { prevent_destroy = true }
  database = "cloudtrail"
  table    = "cloudtrail"

  inputs = [
    {
      pattern = "s3://${aws_s3_bucket.sneller_cloudtrail.bucket}/${local.cloudtrail_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/CloudTrail/{region}/*/*/*/*.json.gz"
      format  = "cloudtrail.json.gz"
    }
  ]
  partitions = [
    {
      field = "region"
    }
  ]
}
