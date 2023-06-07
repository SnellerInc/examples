locals {
    cloudtrail_name = "sneller"
}

# Table that holds all the ingested Cloudtrail log files
resource "sneller_table" "aws_cloudtrail" {
  # Enable this for production to avoid trashing your table
  # lifecycle { prevent_destroy = true }
  database = var.database
  table    = "cloudtrail"

  inputs = [
    {
      pattern = "s3://${aws_s3_bucket.sneller_aws_logging.bucket}/AWSLogs/${data.aws_caller_identity.current.account_id}/CloudTrail/{region}/*/*/*/*.json.gz"
      format  = "cloudtrail.json.gz"
    }
  ]
  partitions = [
    {
      field = "region"
    }
  ]
}

# Enable CloudTrail in the AWS account
resource "aws_cloudtrail" "sneller" {
  # The S3 bucket policy needs to be set before CloudTrail
  # can write to the bucket
  depends_on = [ aws_s3_bucket_policy.sneller_aws_logging ]

  name           = local.cloudtrail_name
  s3_bucket_name = aws_s3_bucket.sneller_aws_logging.id
  
  include_global_service_events = true  # also log global events (i.e. IAM)
  is_multi_region_trail         = true  # log from all AWS regions

  # You can also filter which events should be logged. Refer to
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail
  # for more detailed information
}

# AWS logging bucket policy that allows the CloudTrail service to
# write to the S3 bucket that holds all the source data.
data "aws_iam_policy_document" "sneller_cloudtrail_bucket_policy" {
  # See https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.sneller_aws_logging.arn]
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
    resources = ["${aws_s3_bucket.sneller_aws_logging.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

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
