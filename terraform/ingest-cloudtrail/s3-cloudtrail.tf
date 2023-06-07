# Cloudtrail delivers the log files to the following bucket
resource "aws_s3_bucket" "sneller_cloudtrail" {
  bucket        = "${local.prefix}sneller-cloudtrail"
  force_destroy = true

  tags = {
    Name = "Cloudtrail data"
  }
}

# Public access to the Cloudtrail log bucket is disabled
resource "aws_s3_bucket_public_access_block" "sneller_cloudtrail" {
  bucket = aws_s3_bucket.sneller_cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "sneller_cloudtrail" {
  bucket = aws_s3_bucket.sneller_cloudtrail.id

  rule {
    id = "cloudtrail-lifecycle"

    filter {
      prefix = "${local.cloudtrail_prefix}/"
    }

    expiration {
      days = 7
    }

    status = "Enabled"
  }
}

# Enable S3 event notification to notify the Sneller ingestion
# pipeline to ingest new data as it arrives
resource "aws_s3_bucket_notification" "sneller_cloudtrail" {
  bucket = aws_s3_bucket.sneller_cloudtrail.id

  queue {
    id        = "sneller-cloudtrail"
    queue_arn = data.sneller_tenant_region.sneller.sqs_arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# Cloudtrail should be granted access to deliver log files to the bucket
resource "aws_s3_bucket_policy" "sneller_cloudtrail" {
  bucket = aws_s3_bucket.sneller_cloudtrail.id
  policy = data.aws_iam_policy_document.sneller_cloudtrail_bucket.json
}

data "aws_iam_policy_document" "sneller_cloudtrail_bucket" {
  # See https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.sneller_cloudtrail.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${var.region}:${data.aws_caller_identity.current.account_id}:trail/${local.cloudtrail_name}"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.sneller_cloudtrail.arn}/${local.cloudtrail_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${var.region}:${data.aws_caller_identity.current.account_id}:trail/${local.cloudtrail_name}"]
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}