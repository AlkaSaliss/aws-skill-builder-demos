output "ecr_repository_url" {
  description = "URL of the ECR repository used by the Batch job."
  value       = aws_ecr_repository.this.repository_url
}

output "image_uri" {
  description = "Full ECR image URI used by the Batch job definition."
  value       = "${aws_ecr_repository.this.repository_url}:${var.image_tag}"
}

output "job_queue_arn" {
  description = "ARN of the AWS Batch job queue."
  value       = aws_batch_job_queue.this.arn
}

output "job_queue_name" {
  description = "Name of the AWS Batch job queue."
  value       = aws_batch_job_queue.this.name
}

output "job_definition_arn" {
  description = "ARN of the registered AWS Batch job definition revision."
  value       = aws_batch_job_definition.this.arn
}

output "submit_command" {
  description = "AWS CLI command that submits the Hello World job."
  value       = "aws batch submit-job --job-name ${var.name} --job-queue ${aws_batch_job_queue.this.name} --job-definition ${aws_batch_job_definition.this.arn}"
}
