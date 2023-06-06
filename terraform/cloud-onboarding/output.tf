output "sneller_endpoint" {
  description = "Sneller endpoint"
  value       = "https://snellerd-production.${var.region}.sneller.io"
}

output "sneller_token" {
  description = "Sneller bearer token"
  value       = var.sneller_token
}

output "database" {
  description = "Database name"
  value       = var.database
}

output "table" {
  description = "Table name"
  value       = var.table
}

output "sneller_source" {
  description = "Sneller source bucket"
  value       = aws_s3_bucket.sneller_source.bucket
}

output "sneller_ingest" {
  description = "Sneller ingest bucket"
  value       = aws_s3_bucket.sneller_ingest.bucket
}
