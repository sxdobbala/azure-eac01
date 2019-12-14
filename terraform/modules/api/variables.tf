# These are variables shared across all lambda methods - do NOT put method-specific variables here.

variable "project" {
  description = "Name of the Project"
  default     = "opa"
}

variable "api_name" {
  description = "Name of the API"
  default     = "opa-api"
}

variable "api_description" {
  description = "Internal API for OPA orchestration tasks"
  default     = "Internal API for OPA orchestration tasks"
}

variable "api_policy" {
  description = "API policy JSON document"
}

variable "stage_name" {
  description = "Stage for deployment of the API"
  default     = "dev"
}

variable vpc_id {
  description = "VPC id"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = "list"
}

variable "hybrid_cidr_block" {
  description = "CIDR block for the hybrid network"
  type        = "list"
}

variable private_subnet_ids {
  description = "VPC private subnet ids"
  type        = "list"
}

variable "environment_vars" {
  description = "Environment variables which need to be passed to lambdas"
  type        = "map"

  default = {
    default = "default"
  }
}

variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}

variable "data_load_service_role_name" {
  description = "The name of the Data Load Service role"
}

variable "redshift_egress_sg" {
  description = "the Redshift egress SG that will be attached to individual Lambdas that need it"
}

variable "opa_api_source_code_s3_bucket" {
  description = "S3 bucket with API lambda source code"
}

variable "opa_api_source_code_s3_key" {
  description = "S3 key with API lambda source code"
}

variable "opa_release_sns_role_arn" {
  description = "OPA release step function SNS topic role arn"
}

variable "artifacts_s3_id" {
  description = "S3 bucket for OPA artifacts"
}
