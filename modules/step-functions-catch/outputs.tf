output "state_machine_arn" {
  description = "ARN of the catch demo state machine."
  value       = aws_sfn_state_machine.this.arn
}

output "lambda_function_arn" {
  description = "ARN of the Lambda that selects a catch branch."
  value       = aws_lambda_function.this.arn
}
