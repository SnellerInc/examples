
resource "sneller_tenant_region" "sneller" {
  # Make sure not to set the IAM role, before the
  # role has been granted access to the S3 bucket
  depends_on = [aws_iam_role_policy.sneller_ingest]

  bucket      = aws_s3_bucket.sneller_ingest.bucket
  role_arn    = aws_iam_role.sneller.arn
}