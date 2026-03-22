variable "dexbooru_iam_user_name" {
  type        = string
  description = "The name of the IAM user created for the Dexbooru web application."
}

variable "dexbooru_iam_user_policy_name" {
  type        = string
  description = "The name of the IAM inline policy attached to the Dexbooru web application user."
}

variable "profile_picture_bucket_arn" {
  type        = string
  description = "The ARN of the S3 bucket used for storing profile pictures."
}

variable "post_picture_bucket_arn" {
  type        = string
  description = "The ARN of the S3 bucket used for storing post pictures."
}

variable "post_collection_picture_bucket_arn" {
  type        = string
  description = "The ARN of the S3 bucket used for storing post collection pictures."
}

variable "post_anime_series_queue_arn" {
  type        = string
  description = "The ARN of the SQS queue used for post anime series classification."
}

variable "machine_learning_models_bucket_arn" {
  type        = string
  description = "The ARN of the S3 bucket used for machine learning models."
}

variable "machine_learning_models_iam_user_name" {
  type        = string
  description = "The name of the IAM user for machine learning model storage access."
}

variable "machine_learning_models_iam_user_policy_name" {
  type        = string
  description = "The name of the inline policy attached to the machine learning models IAM user."
}

variable "dexbooru_ai_iam_user_name" {
  type        = string
  description = "The name of the IAM user for the dexbooru_ai service (machine learning models bucket access)."
}

variable "dexbooru_ai_iam_user_policy_name" {
  type        = string
  description = "The name of the inline policy attached to the dexbooru_ai IAM user."
}
