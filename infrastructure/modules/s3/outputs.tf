output "profile_picture_bucket_arn" {
  description = "ARN of the S3 bucket for profile pictures"
  value       = aws_s3_bucket.profile_pictures.arn
}

output "post_picture_bucket_arn" {
  description = "ARN of the S3 bucket for post pictures"
  value       = aws_s3_bucket.post_pictures.arn
}

output "post_collection_picture_bucket_arn" {
  description = "ARN of the S3 bucket for post collection pictures"
  value       = aws_s3_bucket.collection_pictures.arn
}
