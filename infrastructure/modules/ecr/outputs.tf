output "lambda_ecr_repository_details" {
  description = "A map of ECR repository names to their ARN and URL."
  value = {
    for name, repo in aws_ecr_repository.lambda_images : name => {
      arn            = repo.arn
      repository_url = repo.repository_url
    }
  }
}
