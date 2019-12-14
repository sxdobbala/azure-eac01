# ENVIRONMENT SETUP

variable "is_prod" {
  description = "Flag used to determine whether to create prod or non-prod resources"
}

variable "env_prefix" {
  description = "Unique environment prefix to identify resources for an environment, e.g. dev/qa/state/prod or dev-joe"

  # this module is being called from prod-shared and nonprod-shared so for those we can just leave default as ""
  # when it starts being called from base-shared, it will begin to set the proper env_prefix
  default = ""
}

# VPC

variable "vpc_cidr_block" {
  description = "Classless Inter-Domain Routing (CIDR) block for the VPC"
}

variable "vpc" {
  description = "Classless Inter-Domain Routing (CIDR) block for the VPC"
}

variable "ingress_cidr_block" {
  description = "Classless Inter-Domain Routing (CIDR) block for the NACL"
}

variable "publicsubnet01" {
  description = "Classless Inter-Domain Routing (CIDR) block for the NACL"
}

variable "publicsubnet02" {
  description = "Classless Inter-Domain Routing (CIDR) block for the NACL"
}

variable "privatesubnet01" {
  description = "Classless Inter-Domain Routing (CIDR) block for the NACL"
}

variable "privatesubnet02" {
  description = "Classless Inter-Domain Routing (CIDR) block for the NACL"
}

variable "mstr_aws_cloudformation_stack_template_url" {
  description = "Template URL for MicroStrategyOnAWS cloud formation stack"
  default     = "https://s3.amazonaws.com/securecloud-config-prod-us-east-1/cloudformations/MSTRonAWSOrchestration-customer-prod.json"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}

variable "artifacts_s3_bucket" {
  description = "OPA artifacts bucket"
}

variable "appstream_sg_id" {
  description = "ID for AppStream SG created in appstream module"
}
