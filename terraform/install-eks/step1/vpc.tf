data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  cluster_name = "${local.prefix}sneller"
  cidr         = "10.0.0.0/16"
}

module "vpc" {
  # See https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"

  name = "${local.prefix}sneller"
  cidr = local.cidr

  # Use up to 3 availability zones
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  public_subnets  = [for i, az in module.vpc.azs : cidrsubnet(local.cidr, 8, i)]
  private_subnets = [for i, az in module.vpc.azs : cidrsubnet(local.cidr, 8, 128 + i)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}
