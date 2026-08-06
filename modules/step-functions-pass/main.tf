resource "aws_iam_role" "this" {
  name = "${var.name}-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_sfn_state_machine" "this" {
  name     = var.name
  role_arn = aws_iam_role.this.arn

  definition = jsonencode({
    StartAt = "HelloWorld"
    States = {
      HelloWorld = {
        Type = "Pass"
        End  = true
      }
    }
  })
}
