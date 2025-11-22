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
