resource "aws_iam_role_policy" "sneller_cloudtrail" {
  role   = local.sneller_iam_role_name
  name   = "cloudtrail"
  policy = data.aws_iam_policy_document.sneller_cloudtrail.json
}

data "aws_iam_policy_document" "sneller_cloudtrail" {
  # Read access for the cloudtrail bucket
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.sneller_cloudtrail.arn]
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.sneller_cloudtrail.arn}/*"]
  }
}
