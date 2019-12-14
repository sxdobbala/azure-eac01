variable "artifacts_s3_bucket" {
  description = "The bucket where OPA artifacts will be uploaded"
}

variable "aws_region" {
  description = "aws region to create resources"
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

variable "opa_release_s3_prefix" {
  description = "S3 folder where release packages are stored"
  default     = "e2e-releases"
}
