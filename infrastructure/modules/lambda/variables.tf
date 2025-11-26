
variable "post_image_anime_series_classifier_lambda_function_name" {
  description = "The name of the Lambda function for post image classification."
  type        = string
}

variable "post_image_classification_queue_arn" {
  description = "The ARN of the SQS queue for post image classification."
  type        = string
}

variable "lambda_sqs_poller_iam_role_arn" {
  description = "The ARN of the IAM role that the Lambda function will assume to poll messages from SQS."
  type        = string
}

variable "cdn_domain_name" {
  description = "The domain name of the CDN that store image content"
  type        = string
}

variable "gemini_api_key" {
  description = "The API key for the Gemini API"
  type        = string
}

variable "anime_series_classifier_webhook_url" {
  description = "The URL of the webhook to send classification results to in the web application"
  type        = string
}

variable "webhook_secret" {
  description = "The secret for the webhook"
  type        = string
}

variable "lambda_image_ecr_details" {
  description = "A map of ECR repository details for the Lambda function images."
  type = map(object({
    repository_url = string
    arn            = string
  }))
}
