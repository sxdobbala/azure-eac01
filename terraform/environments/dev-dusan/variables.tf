variable "aws_region" {
  description = "AWS region to create resources"
  default     = "us-east-1"
}

variable "aws_replication_region" {
  description = "AWS region to replicate resources"
  default     = "us-west-2"
}

variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

variable "tag_prefix" {
  description = "Tag prefix identifying the organization name or abbreviated name"
  default     = "optum"
}

variable "application_tag" {
  description = "Application tag to be applied to resources"
  default     = "OPA"
}
