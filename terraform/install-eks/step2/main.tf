terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

provider "aws" {
  region = data.terraform_remote_state.step1.outputs.region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.aws_eks_cluster.cluster.name
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        data.aws_eks_cluster.cluster.name
      ]
    }
  }
}

variable "namespace" {
  type        = string
  description = "Kubernetes namespace"
  default     = "sneller"
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

data "terraform_remote_state" "step1" {
  backend = "local"
  config = {
    path = "../step1/terraform.tfstate"
  }
}

data "aws_eks_cluster" "cluster" {
  name = local.cluster_name
}

locals {
  region       = data.terraform_remote_state.step1.outputs.region
  vpc_id       = data.terraform_remote_state.step1.outputs.vpc_id
  prefix       = data.terraform_remote_state.step1.outputs.prefix
  cluster_name = data.terraform_remote_state.step1.outputs.cluster_name
  provider_arn = data.terraform_remote_state.step1.outputs.provider_arn
}