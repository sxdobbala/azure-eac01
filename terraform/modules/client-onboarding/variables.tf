variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

variable "opa_master_lambda_arn" {
  description = "Lambda ARN"
}

variable "opa_client_onboarding_lambda_arn" {
  description = "Lambda ARN"
}

variable "opa_client_redshift_security_lambda_arn" {
  description = "Lambda ARN"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}

variable "opa_deploy_rw_schema_lambda_arn" {
  description = "Lambda ARN"
}

variable "vpc_id" {
  description = "VPC id"
}

variable "artifacts_s3_bucket" {
  description = "The bucket where OPA artifacts will be uploaded"
}

variable "opa_tf_runner_lambda_arn" {
  description = "Lambda ARN"
}

variable "opa_mstr_aws_archive_s3_key" {
  description = "S3 key under which the opa-mstr-aws archive is stored"
}

variable "opa_release_sns_topic_arn" {
  description = "The ARN of the SNS topic used by OPA release process"
}

variable "opa_smoke_test_lambda_arn" {
  description = "Lambda ARN"
}

variable "opa_client_env_move_lambda_arn" {
  description = "Lambda ARN"
}

variable "opa_timezone_change_lambda_arn" {
  description = "Lambda ARN"
}
