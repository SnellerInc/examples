data "aws_route53_zone" "domain" {
  name = var.domain
}

data "aws_lb" "sneller" {
  depends_on = [helm_release.sneller]

  tags = {
    "elbv2.k8s.aws/cluster"    = local.cluster_name
    "ingress.k8s.aws/resource" = "LoadBalancer"
    "ingress.k8s.aws/stack"    = "${var.namespace}/sneller-snellerd"
  }
}

resource "aws_route53_record" "ingress_alias" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = local.fqdn
  type    = "A"

  alias {
    name                   = "dualstack.${data.aws_lb.sneller.dns_name}"
    zone_id                = data.aws_lb.sneller.zone_id
    evaluate_target_health = true
  }
}
