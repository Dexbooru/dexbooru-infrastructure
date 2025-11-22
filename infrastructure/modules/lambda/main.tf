
locals {
  memory_size_mb  = 512
  timeout_seconds = 60

  polling_message_count_size = 10

  lambda_code_base_path = "${path.module}/lambda_code"
}
