variable "domain_name" {
  type        = string
  description = "The full domain name to secure with ACM for Dexbooru CDN"
}

variable "zone_name" {
  type        = string
  description = "The parent Route53 hosted zone for Dexbooru domains"
}
