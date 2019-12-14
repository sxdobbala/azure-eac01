variable "is_prod" {
  description = "Flag used to determine whether to create prod or non-prod resources"
}

variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}

variable "opa_api_source_code_s3_bucket" {
  description = "S3 bucket with API lambda source code"
}

variable "opa_api_source_code_s3_key" {
  description = "S3 key with API lambda source code"
}
