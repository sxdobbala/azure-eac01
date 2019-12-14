variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}
