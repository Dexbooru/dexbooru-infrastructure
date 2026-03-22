
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

variable "machine_learning_models_bucket_name" {
  type        = string
  description = "The S3 bucket name for storing machine learning models"
}

variable "dexbooru_webapp_iam_user_name" {
  type        = string
  description = "The IAM user name for the primary web application"
}

variable "dexbooru_webapp_policy_name" {
  type        = string
  description = "The policy "
}

variable "machine_learning_models_iam_user_name" {
  type        = string
  description = "The IAM user name for machine learning model S3 access"
}

variable "machine_learning_models_iam_policy_name" {
  type        = string
  description = "The inline policy name for the machine learning models IAM user"
}

variable "dexbooru_ai_iam_user_name" {
  type        = string
  description = "The IAM user name for the dexbooru_ai microservice (machine learning models bucket)"
}

variable "dexbooru_ai_iam_policy_name" {
  type        = string
  description = "The inline policy name for the dexbooru_ai IAM user"
}

variable "post_images_anime_series_classificarion_queue_name" {
  description = "The name of the SQS queue for post images anime series classification."
  type        = string
}

variable "post_images_anime_series_classifier_lambda_function_name" {
  description = "The name of the Lambda function for post images anime series classification."
  type        = string
}

variable "gemini_api_key" {
  type        = string
  description = "The API key for the Gemini API"
}

variable "anime_series_classifier_webhook_url" {
  description = "The URL of the webhook to send classification results to in the web application"
  type        = string
}

variable "webhook_secret" {
  description = "The secret for the webhook"
  type        = string
}
