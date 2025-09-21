output "certificate_arn" {
  description = "ARN of the validated ACM certificate for CloudFront"
  value       = aws_acm_certificate_validation.validation.certificate_arn
}

output "domain_name" {
  description = "Domain name secured by the ACM certificate"
  value       = var.domain_name
}

output "validation_record_fqdns" {
  description = "The FQDNs of the Route53 validation records"
  value       = { for key, record in aws_route53_record.validation_record : key => record.fqdn }
}

output "zone_id" {
  description = "The Route53 hosted zone ID for the domain"
  value       = data.aws_route53_zone.selected.zone_id
}
