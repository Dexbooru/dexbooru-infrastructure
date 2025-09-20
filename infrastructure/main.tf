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

  region = var.aws_region

  profile_picture_bucket_name         = var.profile_picture_bucket_name
  post_picture_bucket_name            = var.post_picture_bucket_name
  post_collection_picture_bucket_name = var.post_collection_picture_bucket_name
}

module "build_iam_resources" {
  source = "./modules/iam"

  dexbooru_iam_user_name        = var.dexbooru_webapp_iam_user_name
  dexbooru_iam_user_policy_name = var.dexbooru_webapp_policy_name

  profile_picture_bucket_arn         = module.build_s3_resources.profile_picture_bucket_arn
  post_picture_bucket_arn            = module.build_s3_resources.post_picture_bucket_arn
  post_collection_picture_bucket_arn = module.build_s3_resources.post_collection_picture_bucket_arn
}
