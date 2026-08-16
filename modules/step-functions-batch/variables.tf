variable "name" {
  description = "Name of the Step Functions state machine."
  type        = string
}

variable "definition" {
  description = "Amazon States Language definition for the state machine."
  type        = string
}
