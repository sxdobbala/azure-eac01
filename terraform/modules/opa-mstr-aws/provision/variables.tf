variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

variable "env_id" {
  description = "Environment ID specific to a MSTR instance/cluster, e.g. env-123456"
}

variable "env_name" {
  description = "MSTR Environment Name"
}

variable "app_elb_path" {
  description = "Application Load Balancer Path"
}

variable "opa_release_sns_topic_arn" {
  description = "OPA release SNS topic arn"
}

variable "vpc_id" {
  description = "VPC id"
}

variable "create_listener_rule" {
  description = "True/false flag determining whether listener rule should be added in the current tf run"
  default     = "false"
}

variable "create_dummy_okta_secrets" {
  description = "True/false flag determining whether to add dummy Okta secrets to SSM"
  default     = "false"
}
