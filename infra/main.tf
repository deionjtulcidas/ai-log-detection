terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  project = var.project_name
  tags = {
    Project = local.project
    Owner   = var.owner
    Env     = var.environment
  }
}

# -------------------------------------------------------------------
# S3 – Raw log storage and Lambda trigger
# -------------------------------------------------------------------
module "s3_logs" {
  source               = "./modules/s3_logs"
  bucket_name          = "${local.project}-raw-logs"
  enable_notifications = true
  lambda_arn           = module.lambda_preprocess.lambda_arn
  tags                 = local.tags
}

# -------------------------------------------------------------------
# Kinesis Firehose – optional log stream delivery
# -------------------------------------------------------------------
module "kinesis_firehose" {
  source               = "./modules/kinesis_firehose"
  enabled              = var.enable_firehose
  delivery_bucket_arn  = module.s3_logs.bucket_arn
  delivery_bucket_name = module.s3_logs.bucket_name
  stream_name          = "${local.project}-firehose"
  tags                 = local.tags
}

# -------------------------------------------------------------------
# SNS – alert topic for anomalies and errors
# -------------------------------------------------------------------
module "sns_alerts" {
  source              = "./modules/sns_alerts"
  topic_name          = "${local.project}-alerts"
  email_subscriptions = var.alert_emails
  tags                = local.tags
}

# -------------------------------------------------------------------
# Lambda – log preprocessing & anomaly detection
# -------------------------------------------------------------------
module "lambda_preprocess" {
  source             = "./modules/lambda_preprocess"
  function_name      = "${local.project}-preprocess"
  sns_topic_arn      = module.sns_alerts.topic_arn
  alert_threshold    = var.alert_threshold
  use_sagemaker_stub = var.use_sagemaker_stub
  sagemaker_endpoint = var.sagemaker_endpoint

  environment_vars = {
    PROJECT            = local.project
    ALERT_TOPIC        = module.sns_alerts.topic_arn
    THRESHOLD          = tostring(var.alert_threshold)
    USE_SAGEMAKER_STUB = var.use_sagemaker_stub ? "true" : "false"
    SAGEMAKER_ENDPOINT = var.sagemaker_endpoint
  }

  tags = local.tags
}

# -------------------------------------------------------------------
# CloudWatch – monitoring and alerting
# -------------------------------------------------------------------
module "cloudwatch" {
  source               = "./modules/cloudwatch"
  lambda_function_name = module.lambda_preprocess.function_name
  error_alarm_email    = var.ops_alarm_email
  tags                 = local.tags
}

# -------------------------------------------------------------------
# Outputs
# -------------------------------------------------------------------
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
  value = try(module.kinesis_firehose.stream_name, null)
}
