resource "random_string" "random_prefix" {
  length  = 4
  special = false
  numeric = false
  upper   = false
}

locals {
  # If no prefix is set, then we first check if there is a
  # prefix in the IAM role-name that we can use. If not,
  # then a unique 4 character prefix is used instead.
  _suggested_prefix = endswith(local.sneller_iam_role_name, "-sneller") ? trimsuffix(local.sneller_iam_role_name, "-sneller") : random_string.random_prefix.id
  prefix = var.prefix != "" ? "${var.prefix}-" : "${local._suggested_prefix}-"
}