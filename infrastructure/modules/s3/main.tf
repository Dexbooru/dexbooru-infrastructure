locals {
  s3_buckets = {
    profile_pictures               = var.profile_picture_bucket_name
    post_pictures                  = var.post_picture_bucket_name
    collection_pictures            = var.post_collection_picture_bucket_name
    machine_learning_models        = var.machine_learning_models_bucket_name
    anime_faces_captcha_challenges = var.anime_faces_captcha_challenges_bucket_name
    upload_artifacts               = var.upload_artifacts_bucket_name
  }
}

resource "aws_s3_bucket" "buckets" {
  for_each = local.s3_buckets

  bucket        = each.value
  force_destroy = true

  tags = {
    filepath = "${path.module}/main.tf"
  }
}

# Temporary raw uploads should not linger if a worker/request crashes mid-pipeline.
resource "aws_s3_bucket_lifecycle_configuration" "upload_artifacts" {
  bucket = aws_s3_bucket.buckets["upload_artifacts"].id

  rule {
    id     = "expire-stale-upload-artifacts"
    status = "Enabled"

    filter {
      prefix = "uploads/"
    }

    expiration {
      days = 1
    }
  }
}
