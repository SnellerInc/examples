# Kubernetes namespace for Sneller
resource "kubernetes_namespace" "sneller" {
  metadata {
    name = var.namespace
  }
}
