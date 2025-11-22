
resource "aws_ecr_repository" "lambda_images" {
  name = var.lambda_functions_ecr_repo_name

  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}
