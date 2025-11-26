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

module "build_sqs_resources" {
  source = "./modules/sqs"

  post_images_anime_series_classificarion_queue_name = var.post_images_anime_series_classificarion_queue_name
}

module "build_iam_resources" {
  source = "./modules/iam"

  dexbooru_iam_user_name        = var.dexbooru_webapp_iam_user_name
  dexbooru_iam_user_policy_name = var.dexbooru_webapp_policy_name

  profile_picture_bucket_arn         = module.build_s3_resources.s3_buckets["profile_pictures"].arn
  post_picture_bucket_arn            = module.build_s3_resources.s3_buckets["post_pictures"].arn
  post_collection_picture_bucket_arn = module.build_s3_resources.s3_buckets["collection_pictures"].arn

  post_anime_series_queue_arn = module.build_sqs_resources.post_anime_classification_queue_arn

  depends_on = [module.build_s3_resources, module.build_sqs_resources]
}

module "build_ecr_resources" {
  source = "./modules/ecr"

}

module "build_lambda_function_resources" {
  source = "./modules/lambda"

  cdn_domain_name = module.build_cloudfront_resources.distribution_domain_name

  lambda_image_ecr_details       = module.build_ecr_resources.lambda_ecr_repository_details
  lambda_sqs_poller_iam_role_arn = module.build_iam_resources.sqs_poller_iam_role_arn

  post_image_anime_series_classifier_lambda_function_name = var.post_images_anime_series_classifier_lambda_function_name
  post_image_classification_queue_arn                     = module.build_sqs_resources.post_anime_classification_queue_arn

  gemini_api_key = var.gemini_api_key

  webhook_secret                      = var.webhook_secret
  anime_series_classifier_webhook_url = var.anime_series_classifier_webhook_url

  depends_on = [module.build_sqs_resources, module.build_iam_resources, module.build_cloudfront_resources, module.build_ecr_resources]
}

module "build_cloudfront_resources" {
  source = "./modules/cloudfront"

  s3_origins = module.build_s3_resources.s3_buckets

  depends_on = [module.build_s3_resources]
}
