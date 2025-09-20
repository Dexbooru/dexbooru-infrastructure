output "s3_buckets" {
  description = "A map of the created S3 buckets and their details."
  value = {
    for key, bucket in aws_s3_bucket.buckets : key => {
      id          = bucket.id
      arn         = bucket.arn
      domain_name = bucket.bucket_regional_domain_name
    }
  }
}
