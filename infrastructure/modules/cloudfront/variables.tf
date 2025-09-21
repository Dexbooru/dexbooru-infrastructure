variable "s3_origins" {
  description = "A map of S3 origins for the CloudFront distribution, where the key is a short name for the origin and the value contains bucket details."
  type = map(object({
    id          = string # S3 bucket name
    domain_name = string # S3 bucket regional domain name
    arn         = string # S3 bucket ARN
  }))
  default = {}
}

variable "certificate_arn" {
  type        = string
  description = "ARN of the ACM certificate to use for CloudFront"
}

variable "domain_name" {
  type        = string
  description = "Domain name alias for the CloudFront distribution"
}
