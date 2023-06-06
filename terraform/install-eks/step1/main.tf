terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_type" {
  type        = string
  description = "Instance type for the EKS nodes"
  default     = "m5.large"
}

variable "prefix" {
  type        = string
  description = "Prefix for all resources (required to make resources unique)"
  default     = "" # a 4 character random prefix will be used, when left empty
}
