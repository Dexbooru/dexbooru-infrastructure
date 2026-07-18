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

variable "machine_learning_models_bucket_name" {
  type        = string
  description = "The name of the S3 bucket used to store machine learning models."
}


variable "anime_faces_captcha_challenges_bucket_name" {
  type        = string
  description = "The name of the S3 bucket used to store anime faces captcha challenges."
}

variable "upload_artifacts_bucket_name" {
  type        = string
  description = "The name of the S3 bucket used for temporary raw post upload artifacts before image processing."
}