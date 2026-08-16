output "state_machine_arn" {
  description = "ARN of the callback-token Step Functions state machine."
  value       = aws_sfn_state_machine.this.arn
}

output "queue_url" {
  description = "URL of the SQS callback queue."
  value       = aws_sqs_queue.this.url
}

output "lambda_function_arn" {
  description = "ARN of the Lambda callback worker."
  value       = aws_lambda_function.this.arn
}

output "success_topic_arn" {
  description = "ARN of the SNS topic for successful callbacks."
  value       = aws_sns_topic.success.arn
}

output "failure_topic_arn" {
  description = "ARN of the SNS topic for failed callbacks."
  value       = aws_sns_topic.failure.arn
}
