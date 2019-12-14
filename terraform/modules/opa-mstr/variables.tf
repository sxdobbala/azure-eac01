variable "mstr_stack_name" {
  description = "MSTR instance stack name. e.g env-12345"
}

variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}

variable "environmentName" {
  type        = "string"
  description = "MSTR Environment Name"
}

variable "opa_release_sns_topic_arn" {
  description = "OPA release SNS topic arn"
  default     = "null"
}
