resource "sneller_table" "test" {
  depends_on = [sneller_tenant_region.sneller]

  # Enable this for production to avoid trashing your table
  # lifecycle { prevent_destroy = true }
  database = var.database
  table    = var.table

  inputs = [
    {
      pattern = "s3://${aws_s3_bucket.sneller_source.bucket}/${local.sneller_source_prefix}*.ndjson"
      format  = "json"
    }
  ]
}
