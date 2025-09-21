
variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "The AWS region where terraform resources will be deployed for the Dexbooru infrastructure"
}

variable "profile_picture_bucket_name" {
  type        = string
  description = "The S3 bucket name for storing profile pictures"
}

variable "post_picture_bucket_name" {
  type        = string
  description = "The S3 bucket name for storing post pictures"
}

variable "post_collection_picture_bucket_name" {
  type        = string
  description = "The S3 bucket name for storing post collection pictures"
}

variable "dexbooru_webapp_iam_user_name" {
  type        = string
  description = "The IAM user name for the primary web application"
}

variable "dexbooru_webapp_policy_name" {
  type        = string
  description = "The policy "
}

variable "cdn_domain" {
  type        = string
  description = "The full domain name to secure with ACM for Dexbooru CDN"
}

variable "cdn_zone_name" {
  type        = string
  description = "The parent Route53 hosted zone for Dexbooru domains"
}
