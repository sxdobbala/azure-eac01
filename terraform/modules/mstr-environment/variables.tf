variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

variable "vpc_id" {
  description = "VPC id"
}

variable "artifacts_s3_bucket" {
  description = "The bucket where OPA artifacts will be uploaded"
}

variable "opa_mstr_aws_archive_s3_key" {
  description = "S3 key under which the opa-mstr-aws archive is stored"
}

variable "opa_release_sns_topic_arn" {
  description = "The ARN of the SNS topic used by OPA release process"
}

variable "opa_mstr_stack_lambda_arn" {
  description = "Lambda ARN"
}

variable "opa_tf_runner_lambda_arn" {
  description = "Lambda ARN"
}

variable "opa_mstr_backup_lambda_arn" {
  description = "Lambda ARN"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}

variable "mstr_version" {
  description = "MSTR version used for client deployments"
  default     = "10.11 Critical Update 1"
}

variable "mstr_email" {
  description = "Email supplied to MSTR for client deployments"
  default     = "OPA_AWS_Admins_DL@ds.uhc.com"
}

variable "opa_api_source_code_s3_bucket" {
  description = "S3 bucket with API lambda source code"
}

variable "opa_api_source_code_s3_key" {
  description = "S3 key with API lambda source code"
}
