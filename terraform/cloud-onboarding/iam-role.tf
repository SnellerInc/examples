# Global tenant information
data "sneller_tenant" "tenant" {}

resource "aws_iam_role" "sneller" {
  name               = "${local.prefix}sneller"
  assume_role_policy = data.aws_iam_policy_document.sneller_assume_role.json
}

data "aws_iam_policy_document" "sneller_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [data.sneller_tenant.tenant.tenant_role_arn]
    }

    # Only assume role when the proper tenant ID is passed
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values = [data.sneller_tenant.tenant.tenant_id]
    }
  }
}

resource "aws_iam_role_policy" "sneller_source" {
  role   = aws_iam_role.sneller.id
  name   = "source"
  policy = data.aws_iam_policy_document.sneller_source.json
}

resource "aws_iam_role_policy" "sneller_ingest" {
  role   = aws_iam_role.sneller.id
  name   = "ingest"
  policy = data.aws_iam_policy_document.sneller_ingest.json
}

data "aws_iam_policy_document" "sneller_source" {
  # Read access for the source bucket
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.sneller_source.arn]
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.sneller_source.arn}/*"]
  }
}

data "aws_iam_policy_document" "sneller_ingest" {
  # Read/Write access for the ingest bucket
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.sneller_ingest.arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["db/*"]
    }
  }
  statement {
    actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.sneller_ingest.arn}/db/*"]
  }
}

resource "random_string" "external_id" {
  length  = 12
}