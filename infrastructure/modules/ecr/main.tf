
resource "aws_ecr_repository" "lambda_images" {
  for_each = var.lambda_function_image_repo_names

  name = each.key

  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}
