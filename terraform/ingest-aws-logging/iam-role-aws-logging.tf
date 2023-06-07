resource "aws_iam_role_policy" "sneller_aws_logging" {
  role   = local.sneller_iam_role_name
  name   = "aws-logging"
  policy = data.aws_iam_policy_document.sneller_aws_logging.json
}

data "aws_iam_policy_document" "sneller_aws_logging" {
  # Read access for the cloudtrail bucket
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.sneller_aws_logging.arn]
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.sneller_aws_logging.arn}/*"]
  }
}
