# ENVIRONMENT SETUP

variable "is_prod" {
  description = "Flag used to determine whether to create prod or non-prod resources"
}

variable "aws_region" {
  description = "aws region to create resources"
}

variable "aws_replication_region" {
  description = "Region for replication"
}

variable "aws_profile" {
  description = "aws credential profile"
}

variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

# S3

variable "artifacts_bucket_name_suffix" {
  description = "Suffix for artifacts S3 bucket"
}

variable "client_data_bucket_name_suffix" {
  description = "Suffix for client data S3 bucket"
}

variable "registry_data_bucket_name_suffix" {
  description = "Suffix for registry data S3 bucket"
}

variable "tag_name_identifier" {
  description = "tag name identifier for the aws_base"
}

variable "flat_files_bucket_name_suffix" {
  description = "Suffix for flat files S3 bucket"
}

variable "opa_configuration_bucket_name_suffix" {
  description = "Suffix for opa configuration S3 bucket"
}

variable "s3_mstr_backups_bucket_name_suffix" {
  description = "Suffix for opa-mstr-backups S3 bucket"
}

# AWS INSPECTOR

variable "tag_value_for_instances" {
  description = "Tag value to identify and group the EC2 instances to run the assessment. Key used here is aws_inspector, Value can be true or false"
  default     = "true"
}

variable "assessment_target_name" {
  description = "The name of the assessment target"
  default     = "OPA"
}

# NETWORK

variable "is_hybrid_network" {
  description = "Set to 'true' to add hybrid connectivity to the network."
}

variable "network_name" {
  description = "Name of the network to create"
}

variable "vpc_cidr_block" {
  description = "CIDR block for use by the network."
}

variable "vpc_secondary_cidr_blocks" {
  description = "Additional CIDR blocks for use by the network."
  type        = "list"
  default     = []
}

variable "public_subnets_cidr_blocks" {
  description = "CIDR blocks for the public subnets"
  type        = "list"
}

variable "private_subnets_cidr_blocks" {
  description = "CIDR blocks for the private subnets"
  type        = "list"
}

variable "data_subnets_cidr_blocks" {
  description = "CIDR blocks for the data subnets"
  type        = "list"
}

variable "new_private_subnets_cidr_blocks" {
  description = "CIDR blocks for the new private subnets"
  type        = "list"
  default     = []
}

variable "dataports" {
  description = "The ports for the data network"
  type        = "list"
}

variable "dataports_count" {
  description = "The number of ports for the data network"
}

variable "virtual_interface_id" {
  description = "ID of Direct Connect Virtual Interface"
  default     = ""
}

# TAGGING

variable "global_tags" {
  description = "Global tags to apply to all resources in module"
  type        = "map"

  default = {
    "terraform" = "true"
  }
}

# LINK

variable "link_s3_prefix" {
  description = "Folder prefix for storage of LINK registry data in S3"
  default     = "link-data"
}
