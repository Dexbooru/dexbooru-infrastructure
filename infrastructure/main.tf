terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.13"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

module "build_s3_resources" {
  source = "./modules/s3"

  profile_picture_bucket_name         = var.profile_picture_bucket_name
  post_picture_bucket_name            = var.post_picture_bucket_name
  post_collection_picture_bucket_name = var.post_collection_picture_bucket_name
}

module "build_iam_resources" {
  source = "./modules/iam"

  dexbooru_iam_user_name        = var.dexbooru_webapp_iam_user_name
  dexbooru_iam_user_policy_name = var.dexbooru_webapp_policy_name

  profile_picture_bucket_arn         = module.build_s3_resources.s3_buckets["profile_pictures"].arn
  post_picture_bucket_arn            = module.build_s3_resources.s3_buckets["post_pictures"].arn
  post_collection_picture_bucket_arn = module.build_s3_resources.s3_buckets["collection_pictures"].arn
}


module "build_cloudfront_resources" {
  source = "./modules/cloudfront"

  s3_origins = module.build_s3_resources.s3_buckets

  domain_name     = module.build_route53_resources.domain_name
  certificate_arn = module.build_route53_resources.certificate_arn
}
