resource "sneller_table" "test" {
  depends_on = [sneller_tenant_region.sneller]

  # Enable this for production to avoid trashing your table
  # lifecycle { prevent_destroy = true }
  database = var.database
  table    = var.table

  inputs = [
    {
      pattern = "s3://${data.aws_s3_bucket.sneller_source.bucket}/${var.sneller_path}/${var.sneller_wildcard}"
      format  = var.sneller_format != "" ? var.sneller_format : null
    }
  ]
}
