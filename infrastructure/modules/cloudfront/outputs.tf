output "domain_names" {
  description = "The domain names of the CloudFront distributions."
  value = {
    for key, distribution in aws_cloudfront_distribution.s3_distribution : key => distribution.domain_name
  }
}

output "distributions" {
  description = "The created CloudFront distributions."
  value       = aws_cloudfront_distribution.s3_distribution
}
