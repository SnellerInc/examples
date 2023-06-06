locals {
  commit = substr("7cf4289fb3bcc03464b9f9228391bd7a3348346b", 0, 7)
}

resource "random_id" "index_key" {
  byte_length = 32
}

resource "helm_release" "sneller" {
  name      = "sneller"
  namespace = kubernetes_namespace.sneller.metadata[0].name

  # TODO: Switch to the production https://charts.sneller.io
  repository = "https://charts.sneller-dev.io"
  chart      = "sneller"
  version    = "0.0.0-${local.commit}"

  set {
    name  = "snellerd.image"
    value = "snellerinc/snellerd:${local.commit}-master"
  }

  set {
    name  = "sdb.image"
    value = "snellerinc/sdb:${local.commit}-master"
  }

  set {
    name  = "snellerd.serviceAccountName"
    value = kubernetes_service_account.snellerd.metadata[0].name
    type  = "string"
  }

  set {
    name  = "sdb.serviceAccountName"
    value = kubernetes_service_account.sdb.metadata[0].name
    type  = "string"
  }

  set {
    name  = "sdb.cronJob"
    value = "* * * * *"
  }

  set {
    name  = "sdb.database"
    value = var.database
    type  = "string"
  }

  set {
    name  = "sdb.tablePattern"
    value = var.table
    type  = "string"
  }

  set {
    name  = "snellerd.replicaCount"
    value = 3 # TODO: Fetch from the number of actual nodes
  }

  set {
    name  = "secrets.index.values.snellerIndexKey"
    value = random_id.index_key.b64_std
    type  = "string"
  }

  set {
    name  = "secrets.s3.values.awsRegion"
    value = aws_s3_bucket.sneller_ingest.region
  }

  set {
    name  = "configuration.values.s3Bucket"
    value = "s3://${aws_s3_bucket.sneller_ingest.bucket}"
  }
}

