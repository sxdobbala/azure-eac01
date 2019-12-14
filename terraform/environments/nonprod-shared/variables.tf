variable "aws_region" {
  description = "AWS region for resource creation"
}

variable "aws_replication_region" {
  description = "AWS region for resource replication"
}

variable "env_prefix" {
  description = "Unique environment prefix to identify resources for an environment, e.g. dev/qa/state/prod or dev-joe"
}
