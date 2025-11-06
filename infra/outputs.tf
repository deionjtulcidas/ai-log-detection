output "bucket_name" {
  value = module.s3_logs.bucket_name
}

output "lambda_function_name" {
  value = module.lambda_preprocess.lambda_function_name
}

output "sns_topic_arn" {
  value = module.sns.topic_arn
}

output "firehose_stream_name" {
  value = module.kinesis_firehose.stream_name
}

output "cloudwatch_log_group" {
  value = module.cloudwatch.log_group_name
}
