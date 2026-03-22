
output "sqs_poller_iam_role_arn" {
  description = "The ARN of the IAM role assigned to the SQS poller Lambda function."
  value       = aws_iam_role.sqs_poller_lambda_role.arn
}

output "sqs_poller_iam_role_name" {
  description = "The name of the IAM role assigned to the SQS poller Lambda function."
  value       = aws_iam_role.sqs_poller_lambda_role.name
}

output "dexbooru_ai_access_key_id" {
  description = "Access key ID for the dexbooru_ai IAM user (configure as AWS_ACCESS_KEY_ID for the microservice)."
  value       = aws_iam_access_key.dexbooru_ai.id
}
