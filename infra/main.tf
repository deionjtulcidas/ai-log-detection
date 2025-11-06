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

module "s3_logs" {
  source               = "./modules/s3"
  bucket_name          = "${local.project}-raw-logs"
  enable_notifications = true
  lambda_arn           = module.lambda_preprocess.lambda_arn
  tags                 = local.tags
}

module "firehose" {
  source               = "./modules/firehose"
  enabled              = var.enable_firehose
  delivery_bucket_arn  = module.s3_logs.bucket_arn
  delivery_bucket_name = module.s3_logs.bucket_name
  stream_name          = "${local.project}-firehose"
  tags                 = local.tags
}

module "sns_alerts" {
  source              = "./modules/sns"
  topic_name          = "${local.project}-alerts"
  email_subscriptions = var.alert_emails
  tags                = local.tags
}

module "lambda_preprocess" {
  source          = "./modules/lambda"
  function_name   = "${local.project}-preprocess"
  sns_topic_arn   = module.sns_alerts.topic_arn
  alert_threshold = var.alert_threshold

  environment_vars = {
    PROJECT     = local.project
    ALERT_TOPIC = module.sns_alerts.topic_arn
    THRESHOLD   = tostring(var.alert_threshold)
  }

  tags = local.tags
}

module "cloudwatch" {
  source               = "./modules/cloudwatch"
  lambda_function_name = module.lambda_preprocess.function_name
  error_alarm_email    = var.ops_alarm_email
  tags                 = local.tags
}
