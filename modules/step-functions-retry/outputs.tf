output "state_machine_arn" {
  description = "ARN of the retry demo state machine."
  value       = aws_sfn_state_machine.this.arn
}

output "lambda_function_arn" {
  description = "ARN of the Lambda that always raises CustomError."
  value       = aws_lambda_function.this.arn
}
