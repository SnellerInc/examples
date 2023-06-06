variable "hostname" {
  type        = string
  description = "Hostname (excluding domain) at which the Sneller service should be available"
}

variable "domain" {
  type        = string
  description = "Domain where the Sneller service should be available"
}

locals {
  fqdn = "${var.hostname}.${var.domain}"
}

output "fqdn" {
  description = "FQDN of the Sneller service"
  value       = local.fqdn
}
