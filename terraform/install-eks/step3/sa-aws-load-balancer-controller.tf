locals {
  alb_service_account_name = "aws-load-balancer-controller"
}

resource "kubernetes_service_account" "aws_load_balancer" {
  metadata {
    name      = local.alb_service_account_name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name"      = local.alb_service_account_name
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = module.lb_role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
}

module "lb_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "${local.prefix}sneller-lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = local.provider_arn
      namespace_service_accounts = ["${var.namespace}:${local.alb_service_account_name}"]
    }
  }
}
