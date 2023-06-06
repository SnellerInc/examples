locals {
  sneller_source_prefix = "sample_data/"
}

resource "aws_s3_bucket" "sneller_source" {
  bucket = "${local.prefix}sneller-source"

  tags = {
    Name = "Source bucket for Sneller"
  }
}

resource "aws_s3_bucket_public_access_block" "sneller_source" {
  bucket = aws_s3_bucket.sneller_source.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "sneller_source_data" {
  for_each = fileset(path.module, "${local.sneller_source_prefix}*")
  key      = each.key
  bucket   = aws_s3_bucket.sneller_source.id
  source   = each.key
}
