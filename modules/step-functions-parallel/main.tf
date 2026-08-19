data "archive_file" "sum" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/sum"
  output_path = "${path.module}/sum_lambda.zip"
}

data "archive_file" "min_max" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/min_max"
  output_path = "${path.module}/min_max_lambda.zip"
}

data "archive_file" "average" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/average"
  output_path = "${path.module}/average_lambda.zip"
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
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_lambda_function" "sum" {
  function_name    = "${var.name}-sum"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.sum.output_path
  source_code_hash = data.archive_file.sum.output_base64sha256
  timeout          = 10
  memory_size      = 128

  depends_on = [aws_iam_role_policy.lambda]
}

resource "aws_lambda_function" "min_max" {
  function_name    = "${var.name}-min-max"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.min_max.output_path
  source_code_hash = data.archive_file.min_max.output_base64sha256
  timeout          = 10
  memory_size      = 128

  depends_on = [aws_iam_role_policy.lambda]
}

resource "aws_lambda_function" "average" {
  function_name    = "${var.name}-average"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.average.output_path
  source_code_hash = data.archive_file.average.output_base64sha256
  timeout          = 10
  memory_size      = 128

  depends_on = [aws_iam_role_policy.lambda]
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
    Statement = [{
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = [
        aws_lambda_function.sum.arn,
        aws_lambda_function.min_max.arn,
        aws_lambda_function.average.arn
      ]
    }]
  })
}

resource "aws_sfn_state_machine" "this" {
  name     = var.name
  role_arn = aws_iam_role.state_machine.arn
  definition = templatefile("${path.module}/sfn-def.asl.json", {
    sum_lambda_arn     = aws_lambda_function.sum.arn
    min_max_lambda_arn = aws_lambda_function.min_max.arn
    average_lambda_arn = aws_lambda_function.average.arn
  })

  depends_on = [aws_iam_role_policy.state_machine]
}
