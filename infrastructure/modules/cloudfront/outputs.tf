output "distribution_id" {
  value       = aws_cloudfront_distribution.cdn.id
  description = "CloudFront distribution ID"
}

output "distribution_arn" {
  value       = aws_cloudfront_distribution.cdn.arn
  description = "CloudFront distribution ARN"
}

output "distribution_domain_name" {
  value       = aws_cloudfront_distribution.cdn.domain_name
  description = "CloudFront distribution domain name"
}

output "distribution_hosted_zone_id" {
  value       = aws_cloudfront_distribution.cdn.hosted_zone_id
  description = "Route53 hosted zone ID for alias records to CloudFront"
}
