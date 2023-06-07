resource "aws_s3_bucket_notification" "sneller_source" {
  bucket = aws_s3_bucket.sneller_source.id

  queue {
    id            = "sneller-source"
    queue_arn     = sneller_tenant_region.sneller.sqs_arn
    events        = ["s3:ObjectCreated:*"]
  }
}