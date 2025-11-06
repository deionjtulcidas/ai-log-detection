output "log_bucket_name" {
  value = module.s3_logs.bucket_name
}

output "sns_topic_arn" {
  value = module.sns_alerts.topic_arn
}

output "lambda_function_name" {
  value = module.lambda_preprocess.function_name
}

output "firehose_stream_name" {
  value = try(module.firehose.stream_name, null)
}
