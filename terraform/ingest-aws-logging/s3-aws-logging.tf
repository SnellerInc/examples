# Cloudtrail delivers the log files to the following bucket
resource "aws_s3_bucket" "sneller_aws_logging" {
  bucket        = "${local.prefix}sneller-aws-logging"
  force_destroy = true

  tags = {
    Name = "AWS logging data"
  }
}

# Public access to the Cloudtrail log bucket is disabled
resource "aws_s3_bucket_public_access_block" "sneller_aws_logging" {
  bucket = aws_s3_bucket.sneller_aws_logging.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable S3 event notification to notify the Sneller ingestion
# pipeline to ingest new data as it arrives
resource "aws_s3_bucket_notification" "sneller_aws_logging" {
  bucket = aws_s3_bucket.sneller_aws_logging.id

  queue {
    id        = "sneller-aws-logging"
    queue_arn = data.sneller_tenant_region.sneller.sqs_arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# Cloudtrail should be granted access to deliver log files to the bucket
resource "aws_s3_bucket_policy" "sneller_aws_logging" {
  bucket = aws_s3_bucket.sneller_aws_logging.id
  policy = data.aws_iam_policy_document.sneller_aws_logging_bucket_policy.json
}

data "aws_iam_policy_document" "sneller_aws_logging_bucket_policy" {
  source_policy_documents = [
    data.aws_iam_policy_document.sneller_cloudtrail_bucket_policy.json, # required for CloudTrail logging
    data.aws_iam_policy_document.sneller_flow_bucket_policy.json,       # required for VPC Flow logging
  ]
}
