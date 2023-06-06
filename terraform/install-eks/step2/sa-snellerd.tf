resource "kubernetes_service_account" "snellerd" {
  metadata {
    name      = "snellerd"
    namespace = kubernetes_namespace.sneller.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" : module.iam_eks_snellerd.iam_role_arn
    }
  }
}

module "iam_eks_snellerd" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = "${local.prefix}snellerd"

  role_policy_arns = {
    policy = aws_iam_policy.snellerd.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = local.provider_arn
      namespace_service_accounts = ["${var.namespace}:snellerd"]
    }
  }
}

resource "aws_iam_policy" "snellerd" {
  name   = "${local.prefix}snellerd"
  policy = data.aws_iam_policy_document.snellerd.json
}

data "aws_iam_policy_document" "snellerd" {
  # Read access for the ingest bucket
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.sneller_ingest.arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["db/*"]
    }
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.sneller_ingest.arn}/db/*"]
  }
}
