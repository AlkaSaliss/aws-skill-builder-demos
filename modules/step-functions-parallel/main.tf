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

data "aws_region" "current" {}

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
  timeout          = 40
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
  timeout          = 40
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
  timeout          = 40
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

resource "aws_cloudwatch_log_group" "state_machine" {
  name              = "/aws/vendedlogs/states/${var.name}"
  retention_in_days = 7
}

resource "aws_iam_role_policy" "state_machine_logging" {
  role = aws_iam_role.state_machine.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogDelivery",
        "logs:CreateLogStream",
        "logs:GetLogDelivery",
        "logs:UpdateLogDelivery",
        "logs:DeleteLogDelivery",
        "logs:ListLogDeliveries",
        "logs:PutLogEvents",
        "logs:PutResourcePolicy",
        "logs:DescribeResourcePolicies",
        "logs:DescribeLogGroups"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_sfn_state_machine" "this" {
  name     = var.name
  role_arn = aws_iam_role.state_machine.arn
  type     = "EXPRESS"
  definition = templatefile("${path.module}/sfn-def.asl.json", {
    sum_lambda_arn     = aws_lambda_function.sum.arn
    min_max_lambda_arn = aws_lambda_function.min_max.arn
    average_lambda_arn = aws_lambda_function.average.arn
  })

  logging_configuration {
    include_execution_data = true
    level                  = "ALL"
    log_destination        = "${aws_cloudwatch_log_group.state_machine.arn}:*"
  }

  depends_on = [
    aws_iam_role_policy.state_machine,
    aws_iam_role_policy.state_machine_logging
  ]
}

resource "aws_iam_role" "api_gateway" {
  name = "${var.name}-api-gateway"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "api_gateway" {
  role = aws_iam_role.api_gateway.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "states:StartExecution",
        "states:StartSyncExecution"
      ]
      Resource = aws_sfn_state_machine.this.arn
    }]
  })
}

resource "aws_api_gateway_rest_api" "this" {
  name = "${var.name}-api"
}

resource "aws_api_gateway_resource" "execution" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "execution"
}

resource "aws_api_gateway_method" "execution_post" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.execution.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "execution_post" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.execution.id
  http_method             = aws_api_gateway_method.execution_post.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.region}:states:action/StartSyncExecution"
  credentials             = aws_iam_role.api_gateway.arn
  passthrough_behavior    = "NEVER"

  request_templates = {
    "application/json" = <<-EOF
      {
        "input": "$util.escapeJavaScript($input.json('$'))",
        "stateMachineArn": "${aws_sfn_state_machine.this.arn}"
      }
    EOF
  }

  depends_on = [aws_iam_role_policy.api_gateway]
}

resource "aws_api_gateway_method_response" "execution_post_200" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.execution.id
  http_method = aws_api_gateway_method.execution_post.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "execution_post_200" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.execution.id
  http_method = aws_api_gateway_method.execution_post.http_method
  status_code = aws_api_gateway_method_response.execution_post_200.status_code

  depends_on = [aws_api_gateway_integration.execution_post]
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.execution_post.id,
      aws_api_gateway_integration.execution_post.id,
      aws_api_gateway_integration.execution_post.uri,
      aws_api_gateway_integration.execution_post.request_templates,
      aws_api_gateway_integration_response.execution_post_200.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_integration_response.execution_post_200]
}

resource "aws_api_gateway_stage" "dev" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = "dev"
}
