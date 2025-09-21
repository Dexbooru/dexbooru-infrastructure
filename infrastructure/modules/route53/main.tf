locals {
  record_ttl = 60
}

data "aws_route53_zone" "selected" {
  name         = var.zone_name
  private_zone = false
}

resource "aws_acm_certificate" "certificate" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation_record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = aws_acm_certificate.certificate.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.certificate.domain_validation_options[0].resource_record_type
  ttl     = local.record_ttl
  records = [aws_acm_certificate.certificate.domain_validation_options[0].resource_record_value]
}

resource "aws_acm_certificate_validation" "validation" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [aws_route53_record.validation_record.fqdn]
}
