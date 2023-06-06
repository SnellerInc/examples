resource "aws_acm_certificate" "sneller" {
  domain_name = local.fqdn

  # beware of including domains used by other regions. See https://github.com/SnellerInc/sneller-core/issues/2784
  subject_alternative_names = []
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "sneller_cert" {
  for_each = {
    for dvo in aws_acm_certificate.sneller.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.domain.zone_id
}

resource "aws_acm_certificate_validation" "sneller" {
  timeouts { # to avoid getting stuck for the entire default duration i.e. 75min
    create = "15m"
  }
  certificate_arn         = aws_acm_certificate.sneller.arn
  validation_record_fqdns = [for record in aws_route53_record.sneller_cert : record.fqdn]
}
