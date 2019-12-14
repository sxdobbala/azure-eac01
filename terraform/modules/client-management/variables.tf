variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

variable "mstr_backup_sfn_arn" {
  description = "SFN workflow to create MSTR backup"
}

variable "mstr_environment_create_sfn_arn" {
  description = "SFN workflow to create MSTR environments"
}

variable "mstr_environment_destroy_sfn_arn" {
  description = "SFN workflow to destroy MSTR environments"
}

variable "opa_release_sfn_arn" {
  description = "SFN workflow to run OPA releases"
}

variable "client_onboarding_sfn_arn" {
  description = "SFN workflow to onboard new clients onto environments"
}

variable "client_stack_rotation_sfn_arn" {
  description = "SFN workflow to onboard existing clients onto new environments"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}

variable "ci_sns_topic" {
  description = "SNS topic where Continuous Integration (CI) updates are published"
}

variable "opa_operations_sns_topic" {
  description = "SNS topic where OPA operations updates are published"
}
