variable "bucket_name" { type = string }
variable "tags" { type = map(string) }
variable "enable_notifications" { type = bool }
variable "lambda_arn" { type = string }

resource "aws_s3_bucket" "logs" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "v" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lc" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-multipart-uploads"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_lambda_permission" "s3_invoke" {
  count         = var.enable_notifications ? 1 : 0
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.logs.arn
}

resource "aws_s3_bucket_notification" "notify" {
  count  = var.enable_notifications ? 1 : 0
  bucket = aws_s3_bucket.logs.id

  lambda_function {
    lambda_function_arn = var.lambda_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3_invoke]
}

output "bucket_name" {
  value = aws_s3_bucket.logs.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.logs.arn
}
