variable "aws_region" {
  description = "aws region to create resources"
}

variable "aws_replication_region" {
  description = "Region for replication"
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
