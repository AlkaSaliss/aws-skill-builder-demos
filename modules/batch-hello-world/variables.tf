variable "name" {
  description = "Name prefix for the AWS Batch resources."
  type        = string
}

variable "image_tag" {
  description = "Tag of the image in the module-managed ECR repository."
  type        = string
  default     = "latest"
}

variable "job_vcpus" {
  description = "Number of vCPUs reserved for the job."
  type        = number
  default     = 0.25
}

variable "job_memory" {
  description = "Memory in MiB reserved for the job."
  type        = number
  default     = 512

  validation {
    condition     = var.job_memory >= 512
    error_message = "job_memory must be at least 512 MiB for AWS Batch Fargate."
  }
}
