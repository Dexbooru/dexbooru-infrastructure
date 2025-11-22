
output "lambda_images_repository_url" {
  value       = aws_ecr_repository.lambda_images.repository_url
  description = "URL of the ECR repository for lambda images"
}
