
locals {
  max_anime_series_classification_message_size_bytes             = 2048
  max_anime_series_classification_message_retention_time_seconds = 86400 # 1 day
  anime_series_classification_messages_delay_time_seconds        = 180   # 3 minutes
}

resource "aws_sqs_queue" "anime_series_classification_queue" {
  name                      = var.post_images_anime_series_classificarion_queue_name
  delay_seconds             = local.anime_series_classification_messages_delay_time_seconds
  message_retention_seconds = local.max_anime_series_classification_message_retention_time_seconds
  max_message_size          = local.max_anime_series_classification_message_size_bytes

  tags = {
    Name         = var.post_images_anime_series_classificarion_queue_name
    Descriptionn = "The SQS queue for post images anime series classification pulled by lambda function which uses Gemini LLM model"
    filepath     = "${path.module}/main.tf"
  }
}
