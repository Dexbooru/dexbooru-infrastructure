
locals {
  memory_size_mb  = 512
  timeout_seconds = 120

  polling_message_count_size = 10

  lambda_code_base_path = "${path.module}/lambda_code"
}


resource "aws_lambda_function" "post_image_classification_lambda" {
  function_name = var.post_image_anime_series_classifier_lambda_function_name
  description   = "Lambda function to classify anime series in posted images using Gemini API."
  image_uri     = "${var.lambda_image_ecr_details["lambda-function-post-image-anime-series-classifier"].repository_url}:latest"
  package_type  = "Image"

  architectures = ["x86_64"]

  image_config {
    entry_point = ["/lambda-entrypoint.sh"]
    command     = ["bootstrap"]
  }

  role = var.lambda_sqs_poller_iam_role_arn

  memory_size = local.memory_size_mb
  timeout     = local.timeout_seconds

  environment {
    variables = {
      CDN_DOMAIN_NAME = var.cdn_domain_name
      GEMINI_API_KEY  = var.gemini_api_key
      WEBHOOK_SECRET  = var.webhook_secret
      WEBHOOK_URL     = var.anime_series_classifier_webhook_url
      ENVIRONMENT     = "production"
    }
  }

  tags = {
    filepath = "${path.module}/main.tf"
  }
}


resource "aws_cloudwatch_log_group" "post_image_classification_lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.post_image_classification_lambda.function_name}"
  retention_in_days = 1

  tags = {
    filepath = "${path.module}/main.tf"
  }
}


resource "aws_lambda_event_source_mapping" "sqs_event_source_mapping" {
  event_source_arn = var.post_image_classification_queue_arn
  function_name    = aws_lambda_function.post_image_classification_lambda.arn

  enabled                 = true
  batch_size              = local.polling_message_count_size
  function_response_types = ["ReportBatchItemFailures"]
}
