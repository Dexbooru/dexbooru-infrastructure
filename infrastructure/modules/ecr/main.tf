locals {
  lambda_marker_files = fileset("../lambda/lambda_code", "marker.txt")
  lambda_directory_names = toset([
    for marker_file in local.lambda_marker_files : "lambda-function-${dirname(marker_file)}"
  ])
}

resource "aws_ecr_repository" "lambda_images" {
  for_each = local.lambda_directory_names

  name = each.key

  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    filepath = "${path.module}/main.tf"
  }
}
