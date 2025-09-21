output "certificate_arn" {
  description = "ARN of the validated ACM certificate for CloudFront"
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "domain_name" {
  description = "Domain name secured by the ACM certificate"
  value       = var.domain_name
}

output "validation_record_fqdn" {
  description = "The FQDN of the Route53 validation record"
  value       = aws_route53_record.validation.fqdn
}

output "zone_id" {
  description = "The Route53 hosted zone ID for the domain"
  value       = data.aws_route53_zone.neetbyte.zone_id
}
