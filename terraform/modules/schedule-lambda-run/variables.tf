variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

variable "rule_name" {
  description = "Name for the scheduled cloudwatch rule"
  default     = ""
}

# https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html
variable "schedule_expression" {
  description = "Schedule expression for the cloudwatch rule (in valid cron format)"
}

variable "lambda_name" {
  description = "Name of the lambda function to schedule"
}

variable "lambda_arn" {
  description = "ARN of the lambda function to schedule"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}
