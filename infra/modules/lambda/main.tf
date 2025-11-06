variable "function_name"      { type = string }
variable "sns_topic_arn"      { type = string }
variable "alert_threshold"    { type = number }
variable "use_sagemaker_stub" { type = bool }
variable "sagemaker_endpoint" { type = string }
variable "environment_vars"   { type = map(string) }
variable "tags"               { type = map(string) }

data "archive_file" "zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/lambda.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.function_name}-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
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
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.sns_topic_arn
      },
      {
        Effect   = var.use_sagemaker_stub ? "Deny" : "Allow"
        Action   = ["sagemaker:InvokeEndpoint"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "fn" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  filename      = data.archive_file.zip.output_path
  timeout       = 30
  memory_size   = 256

  environment {
    variables = merge(
      var.environment_vars,
      {
        USE_SAGEMAKER_STUB = var.use_sagemaker_stub ? "true" : "false"
        SAGEMAKER_ENDPOINT = var.sagemaker_endpoint
      }
    )
  }

  tags = var.tags
}

output "lambda_arn" {
  value = aws_lambda_function.fn.arn
}

output "function_name" {
  value = aws_lambda_function.fn.function_name
}
