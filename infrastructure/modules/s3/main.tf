resource "aws_s3_bucket" "profile_pictures" {
  bucket        = var.profile_picture_bucket_name
  force_destroy = true
  region        = var.region
}

resource "aws_s3_bucket_acl" "profile_picture_bucket_acl" {
  bucket = aws_s3_bucket.profile_pictures.id
  acl    = "private"
}

resource "aws_s3_bucket" "post_pictures" {
  bucket        = var.post_picture_bucket_name
  force_destroy = true
  region        = var.region
}

resource "aws_s3_bucket_acl" "post_picture_bucket_acl" {
  bucket = aws_s3_bucket.post_pictures.id
  acl    = "private"
}

resource "aws_s3_bucket" "collection_pictures" {
  bucket        = var.post_collection_picture_bucket_name
  force_destroy = true
  region        = var.region
}

resource "aws_s3_bucket_acl" "post_collection_bucket_acl" {
  bucket = aws_s3_bucket.collection_pictures.id
  acl    = "private"
}
