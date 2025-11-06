variable "topic_name" { type = string }
variable "email_subscriptions" { type = list(string) }
variable "tags" { type = map(string) }

resource "aws_sns_topic" "alerts" {
  name = var.topic_name
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  for_each  = toset(var.email_subscriptions)
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

output "topic_arn" { value = aws_sns_topic.alerts.arn }
