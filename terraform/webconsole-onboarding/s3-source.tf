locals {
  sneller_source_bucket_name = trimsuffix(trimprefix(var.sneller_source, "s3://"),"/")
}

data "aws_s3_bucket" "sneller_source" {
  bucket = local.sneller_source_bucket_name
}

resource "aws_s3_bucket_notification" "sneller_source" {
  bucket = data.aws_s3_bucket.sneller_source.id

  queue {
    id            = "sneller-source"
    queue_arn     = sneller_tenant_region.sneller.sqs_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = var.sneller_path
  }
}