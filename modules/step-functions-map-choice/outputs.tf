output "state_machine_arn" {
  description = "ARN of the Map and Choice demo state machine."
  value       = aws_sfn_state_machine.this.arn
}

output "orders_table_name" {
  description = "Name of the DynamoDB table storing high-priority orders."
  value       = aws_dynamodb_table.orders.name
}

output "orders_table_arn" {
  description = "ARN of the DynamoDB table storing high-priority orders."
  value       = aws_dynamodb_table.orders.arn
}
