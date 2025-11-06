variable "enabled" { type = bool }
variable "delivery_bucket_arn" { type = string }
variable "delivery_bucket_name" { type = string }
variable "stream_name" { type = string }
variable "tags" { type = map(string) }

resource "aws_iam_role" "firehose_role" {
  count = var.enabled ? 1 : 0
  name  = "${var.stream_name}-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "firehose.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "firehose_policy" {
  count = var.enabled ? 1 : 0
  role  = aws_iam_role.firehose_role[0].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["s3:PutObject", "s3:PutObjectAcl", "s3:AbortMultipartUpload", "s3:ListBucket", "s3:GetBucketLocation"], Resource = [var.delivery_bucket_arn, "${var.delivery_bucket_arn}/*"] }
    ]
  })
}

resource "aws_kinesis_firehose_delivery_stream" "stream" {
  count       = var.enabled ? 1 : 0
  name        = var.stream_name
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.firehose_role[0].arn
    bucket_arn         = var.delivery_bucket_arn
    buffering_interval = 60
    buffering_size     = 5
    compression_format = "GZIP"
  }

  tags = var.tags
}

output "stream_name" {
  value       = try(aws_kinesis_firehose_delivery_stream.stream[0].name, null)
  description = "Null if disabled"
}
