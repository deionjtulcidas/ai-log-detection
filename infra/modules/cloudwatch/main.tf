variable "lambda_function_name" { type = string }
variable "error_alarm_email"    { type = string }
variable "tags"                 { type = map(string) }

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
  tags = var.tags
}

resource "aws_sns_topic" "ops" {
  count = length(trimspace(var.error_alarm_email)) > 0 ? 1 : 0
  name  = "ops-alarms"
  tags  = var.tags
}

resource "aws_sns_topic_subscription" "ops_email" {
  count     = length(trimspace(var.error_alarm_email)) > 0 ? 1 : 0
  topic_arn = aws_sns_topic.ops[0].arn
  protocol  = "email"
  endpoint  = var.error_alarm_email
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.lambda_function_name}-Errors"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  dimensions          = { FunctionName = var.lambda_function_name }
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  alarm_actions       = length(aws_sns_topic.ops) > 0 ? [aws_sns_topic.ops[0].arn] : []
  tags                = var.tags
}
