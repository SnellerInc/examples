resource "aws_flow_log" "sneller" {
  # The S3 bucket policy needs to be set before flow logging
  # can write to the bucket
  depends_on = [ aws_s3_bucket_policy.sneller_aws_logging ]

  log_destination_type = "s3"
  log_destination      = aws_s3_bucket.sneller_aws_logging.arn
  traffic_type         = "ALL"
  vpc_id               = data.aws_vpc.default.id 
}

data "aws_vpc" "default" {
  default = true
}

# Table that holds all the ingested flow log files
resource "sneller_table" "aws_flow" {
  # Enable this for production to avoid trashing your table
  # lifecycle { prevent_destroy = true }
  database = var.database
  table    = "flow"

  inputs = [
    {
      pattern   = "s3://${aws_s3_bucket.sneller_aws_logging.bucket}/AWSLogs/${data.aws_caller_identity.current.account_id}/vpcflowlogs/{region}/*/*/*/*.log.gz"
      format    = "csv.gz"
      csv_hints = {
        skip_records = 1
        separator = " "
        fields = [
          { name = "version",      type = "int"    },
          { name = "account_id",   type = "string" },
          { name = "interface_id", type = "string" },
          { name = "srcaddr",      type = "string" },
          { name = "dstaddr",      type = "string" },
          { name = "srcport",      type = "int"    },
          { name = "dstport",      type = "int"    },
          { name = "protocol",     type = "int"    },
          { name = "packets",      type = "int"    },
          { name = "bytes",        type = "int"    },
          { name = "start",        type = "datetime", format = "unix_seconds" },
          { name = "end",          type = "datetime", format = "unix_seconds" },
          { name = "action",       type = "string" },
          { name = "log_status",   type = "string" },
        ]
      }
    }
  ]
  partitions = [
    {
      field = "region"
    }
  ]
}

# AWS logging bucket policy that allows the Flow logging delivery service to
# write to the S3 bucket that holds all the source data.
data "aws_iam_policy_document" "sneller_flow_bucket_policy" {
  # See https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-s3.html
  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.sneller_aws_logging.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }

  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl","s3:ListBucket"]
    resources = [aws_s3_bucket.sneller_aws_logging.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}
