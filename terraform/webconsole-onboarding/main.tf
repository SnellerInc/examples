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

variable "sneller_source" {
  type        = string
  description = "Source bucket URL (i.e. s3://my-source-bucket)"
}

variable "sneller_path" {
  type        = string
  description = "Source path (prefix to S3 objects)"
}

variable "sneller_wildcard" {
  type        = string
  description = "Extension of source objects (i.e. *.json.gz)"
}

variable "sneller_format" {
  type        = string
  description = "Format of source objects (default uses auto-detection based on the object's extension)"
  default     = ""
}

variable "database" {
  type        = string
  description = "Database name"
  default     = "tutorial"
}

variable "table" {
  type        = string
  description = "Table name"
  default     = "table1"
}
