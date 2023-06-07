terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    sneller = {
      source = "snellerinc/sneller"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "sneller" {
  api_endpoint   = "https://api-production.${var.region}.sneller.io/"
  default_region = var.region
  token          = var.sneller_token
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "sneller_token" {
  type        = string
  description = "Sneller token"
}

variable "prefix" {
  type        = string
  description = "Prefix for all resources (required to make resources unique)"
  default     = "" # a 4 character random prefix will be used, when left empty
}
