locals {
  s3_buckets = {
    profile_pictures    = var.profile_picture_bucket_name
    post_pictures       = var.post_picture_bucket_name
    collection_pictures = var.post_collection_picture_bucket_name
  }
}

resource "aws_s3_bucket" "buckets" {
  for_each      = local.s3_buckets
  bucket        = each.value
  force_destroy = true
}
