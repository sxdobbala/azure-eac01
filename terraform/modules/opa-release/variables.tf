variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

variable "deploy_opa_lambda_arn" {
  description = "The arn of deploy_opa lambda"
}

variable "opa_release_s3_bucket" {
  description = "S3 artifacts bucket contains opa-releases package"
}

variable "opa_release_s3_prefix" {
  description = "S3 folder where release packages are stored"
  default     = "e2e-releases"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}

variable "deploy_mstr_lambda_arn" {
  description = "The arn of opa-mstr-migration lambda"
}

variable "opa_release_sns_topic_arn" {
  description = "OPA release step function SNS topic arn"
}

variable "opa_release_sns_role_arn" {
  description = "OPA release step function SNS topic role arn"
}

variable "artifacts_s3_bucket" {
  description = "The bucket where OPA artifacts will be uploaded"
}

variable "mstr_postinstall_lambda_arn" {
  description = "The arn of mstr-postinstall lambda"
}

variable "opa_master_lambda_arn" {
  description = "The arn of opa-master lambda"
}

variable "opa_api_source_code_s3_bucket" {
  description = "S3 bucket with API lambda source code"
}

variable "opa_api_source_code_s3_key" {
  description = "S3 key with API lambda source code"
}

variable "opa_deploy_rw_schema_lambda_arn" {
  description = "The arn of opa-deploy-rw-schema lambda"
}
