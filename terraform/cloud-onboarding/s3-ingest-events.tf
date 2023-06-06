
resource "aws_s3_bucket_notification" "sneller_ingest" {
  bucket = aws_s3_bucket.sneller_ingest.id

  queue {
    id            = "config-updates"
    queue_arn     = sneller_tenant_region.sneller.sqs_arn
    events        = ["s3:ObjectCreated:*","s3:ObjectRemoved:*"]
    filter_suffix = ".json"
  }
}