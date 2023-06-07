locals {
    cloudtrail_name   = "sneller"
    cloudtrail_prefix = "sneller"
}

resource "aws_cloudtrail" "sneller" {
  # The S3 bucket policy needs to be set before CloudTrail
  # can write to the bucket
  depends_on = [ aws_s3_bucket_policy.sneller_cloudtrail ]

  name           = local.cloudtrail_name
  s3_bucket_name = aws_s3_bucket.sneller_cloudtrail.id
  s3_key_prefix  = local.cloudtrail_prefix
  
  include_global_service_events = true  # also log global events (i.e. IAM)
  is_multi_region_trail         = true  # log from all AWS regions

  # You can also filter which events should be logged. Refer to
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail
  # for more detailed information
}