variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "ai-log-detection"
}

variable "owner" {
  description = "Owner of the project"
  type        = string
  default     = "Deion Tulcidas"
}

variable "alert_emails" {
  description = "List of email addresses to subscribe to SNS alerts"
  type        = list(string)
  default     = ["djt61@pitt.edu"]
}

variable "alert_threshold" {
  description = "Alert threshold value for anomaly detection"
  type        = number
  default     = 80
}

variable "ops_alarm_email" {
  description = "Email address for operational alarms"
  type        = string
  default     = "dj161@pitt.edu"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project = "ai-log-detection"
    Owner   = "Deion Tulcidas"
    Env     = "dev"
  }
}

variable "enable_firehose" {
  description = "Enable or disable the Kinesis Firehose module"
  type        = bool
  default     = true
}
