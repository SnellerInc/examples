resource "random_string" "random_prefix" {
  length  = 4
  special = false
  numeric = false
  upper   = false
}

locals {
  prefix = var.prefix != "" ? "${var.prefix}-" : "${random_string.random_prefix.id}-"
}