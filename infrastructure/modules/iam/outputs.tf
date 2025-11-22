
output "sqs_poller_iam_role_arn" {
  description = "The ARN of the IAM role assigned to the SQS poller Lambda function."
  value       = aws_iam_role.sqs_poller_lambda_role.arn
}

output "sqs_poller_iam_role_name" {
  description = "The name of the IAM role assigned to the SQS poller Lambda function."
  value       = aws_iam_role.sqs_poller_lambda_role.name
}
