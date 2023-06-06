resource "kubernetes_service_account" "sdb" {
  metadata {
    name      = "sdb"
    namespace = kubernetes_namespace.sneller.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" : module.iam_eks_sdb.iam_role_arn
    }
  }
}

module "iam_eks_sdb" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.20.0"

  role_name = "${local.prefix}sdb"

  role_policy_arns = {
    policy = aws_iam_policy.sdb.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = local.provider_arn
      namespace_service_accounts = ["${var.namespace}:sdb"]
    }
  }
}

resource "aws_iam_policy" "sdb" {
  name   = "${local.prefix}sdb"
  policy = data.aws_iam_policy_document.sdb.json
}

data "aws_iam_policy_document" "sdb" {
  # Read access for the source bucket
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.sneller_source.arn]
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.sneller_source.arn}/*"]
  }

  # Read/Write access for the ingest bucket
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
    actions   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.sneller_ingest.arn}/db/*"]
  }
}
