variable "region" {
  type        = string
  description = "The AWS region in which all resources (S3 buckets, compute, etc.) will be created."
}

variable "profile_picture_bucket_name" {
  type        = string
  description = "The name of the S3 bucket dedicated to storing user profile pictures."
}

variable "post_picture_bucket_name" {
  type        = string
  description = "The name of the S3 bucket used to store individual post images."
}

variable "post_collection_picture_bucket_name" {
  type        = string
  description = "The name of the S3 bucket used to store images associated with post collections."
}
