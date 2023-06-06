output "region" {
  description = "AWS region"
  value       = var.region
}

output "prefix" {
  description = "Prefix for all resources"
  value       = local.prefix
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "vpc_id" {
  description = "VPC identifier"
  value       = module.vpc.vpc_id
}

output "provider_arn" {
  description = "OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}
