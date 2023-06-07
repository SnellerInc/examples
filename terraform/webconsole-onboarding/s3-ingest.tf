resource "aws_s3_bucket" "sneller_ingest" {
  bucket        = "${local.prefix}sneller-ingest"
  force_destroy = true

  tags = {
    Name = "Ingest bucket for Sneller"
  }
}

resource "aws_s3_bucket_public_access_block" "sneller_ingest" {
  bucket = aws_s3_bucket.sneller_ingest.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_notification" "sneller_ingest" {
  bucket = aws_s3_bucket.sneller_ingest.id

  queue {
    id            = "config-updates"
    queue_arn     = sneller_tenant_region.sneller.sqs_arn
    events        = ["s3:ObjectCreated:*","s3:ObjectRemoved:*"]
    filter_suffix = ".json"
  }
}