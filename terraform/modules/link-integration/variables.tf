variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
  default     = ""
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}

variable "s3_bucket" {
  description = "The bucket where registry data will be uploaded"
}

variable "s3_prefix" {
  description = "The bucket prefix where LINK registry data will be uploaded"
  default     = "link-data"
}

variable "registry_api_url" {
  description = "The url for the DataLoader registry API"
}

variable "link_service_role_arn" {
  description = "ARN of the role the LINK team is using to send/receive SQS messages"
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

variable "opa_api_source_code_s3_bucket" {
  description = "S3 bucket with API lambda source code"
}

variable "opa_api_source_code_s3_key" {
  description = "S3 key with API lambda source code"
}

variable "dataloader_egress_sg_id" {
  description = "Dataloader egress Security group Id"
}