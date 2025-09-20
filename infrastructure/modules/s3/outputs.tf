output "profile_picture_bucket_arn" {
  description = "ARN of the S3 bucket for profile pictures"
  value       = aws_s3_bucket.profile_pictures.arn
}

output "profile_picture_bucket_id" {
  description = "ID (name) of the S3 bucket for profile pictures"
  value       = aws_s3_bucket.profile_pictures.id
}

output "profile_picture_bucket_domain_name" {
  description = "Regional domain name of the S3 bucket for profile pictures"
  value       = aws_s3_bucket.profile_pictures.bucket_regional_domain_name
}

output "post_picture_bucket_arn" {
  description = "ARN of the S3 bucket for post pictures"
  value       = aws_s3_bucket.post_pictures.arn
}

output "post_picture_bucket_id" {
  description = "ID (name) of the S3 bucket for post pictures"
  value       = aws_s3_bucket.post_pictures.id
}

output "post_picture_bucket_domain_name" {
  description = "Regional domain name of the S3 bucket for post pictures"
  value       = aws_s3_bucket.post_pictures.bucket_regional_domain_name
}

output "post_collection_picture_bucket_arn" {
  description = "ARN of the S3 bucket for post collection pictures"
  value       = aws_s3_bucket.collection_pictures.arn
}

output "post_collection_picture_bucket_id" {
  description = "ID (name) of the S3 bucket for post collection pictures"
  value       = aws_s3_bucket.collection_pictures.id
}

output "post_collection_picture_bucket_domain_name" {
  description = "Regional domain name of the S3 bucket for post collection pictures"
  value       = aws_s3_bucket.collection_pictures.bucket_regional_domain_name
}
