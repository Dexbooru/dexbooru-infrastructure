
output "post_anime_classification_queue_arn" {
  description = "The ARN of the SQS queue for post images anime series classification."
  value       = aws_sqs_queue.anime_series_classification_queue.arn
}

output "post_anime_classification_queue_url" {
  description = "The URL of the SQS queue for post images anime series classification."
  value       = aws_sqs_queue.anime_series_classification_queue.id
}

output "post_anime_classification_queue_name" {
  description = "The name of the SQS queue for post images anime series classification."
  value       = aws_sqs_queue.anime_series_classification_queue.name
}
