data "sneller_tenant_region" "sneller" {
  region = var.region
}

locals {
  # Role name           is the text after the slash in the IAM role ARN
  sneller_iam_role_name = split("/", data.sneller_tenant_region.sneller.role_arn)[1]
}