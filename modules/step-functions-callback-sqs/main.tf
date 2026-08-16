data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_sqs_queue" "this" {
  name                       = "${var.name}-tasks"
  visibility_timeout_seconds = 200
  message_retention_seconds  = 86400
}

resource "aws_sns_topic" "success" {
  name = "${var.name}-success"
}

resource "aws_sns_topic" "failure" {
  name = "${var.name}-failure"
}

resource "aws_iam_role" "lambda" {
  name = "${var.name}-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda" {
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ReceiveMessage"
        ]
        Resource = aws_sqs_queue.this.arn
      },
      {
        Effect = "Allow"
        Action = [
          "states:SendTaskFailure",
          "states:SendTaskSuccess"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "this" {
  function_name    = "${var.name}-worker"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 180
  memory_size      = 128

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.this.url
    }
  }

  depends_on = [aws_iam_role_policy.lambda]
}

resource "aws_lambda_event_source_mapping" "this" {
  event_source_arn = aws_sqs_queue.this.arn
  function_name    = aws_lambda_function.this.arn
  batch_size       = 1
  enabled          = true
}

resource "aws_iam_role" "state_machine" {
  name = "${var.name}-state-machine"

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

resource "aws_iam_role_policy" "state_machine" {
  role = aws_iam_role.state_machine.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.this.arn
      },
      {
        Effect = "Allow"
        Action = "sns:Publish"
        Resource = [
          aws_sns_topic.success.arn,
          aws_sns_topic.failure.arn
        ]
      }
    ]
  })
}

resource "aws_sfn_state_machine" "this" {
  name     = var.name
  role_arn = aws_iam_role.state_machine.arn
  definition = templatefile("${path.module}/state_machine.asl.json", {
    failure_topic_arn = aws_sns_topic.failure.arn
    queue_url         = aws_sqs_queue.this.url
    success_topic_arn = aws_sns_topic.success.arn
  })

  depends_on = [aws_iam_role_policy.state_machine]
}
