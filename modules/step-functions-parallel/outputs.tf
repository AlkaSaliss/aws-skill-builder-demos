output "state_machine_arn" {
  description = "ARN of the parallel demo state machine."
  value       = aws_sfn_state_machine.this.arn
}

output "sum_lambda_arn" {
  description = "ARN of the sum Lambda."
  value       = aws_lambda_function.sum.arn
}

output "min_max_lambda_arn" {
  description = "ARN of the minimum/maximum Lambda."
  value       = aws_lambda_function.min_max.arn
}

output "average_lambda_arn" {
  description = "ARN of the average Lambda."
  value       = aws_lambda_function.average.arn
}

output "api_invoke_url" {
  description = "URL for starting a parallel workflow execution."
  value       = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${data.aws_region.current.region}.amazonaws.com/dev/execution"
}
