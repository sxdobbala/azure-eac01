variable "is_hybrid" {
  description = "Hybrid network conditional flag - set to true to turn on hybrid connectivity"
  default     = "false"
}

variable "virtual_interface_id" {
  description = "ID of Direct Connect Virtual Interface"
  default     = ""
}

variable "network_name" {
  description = "Name for the Network"
}

variable "vpc_cidr_block" {
  description = "Classless Inter-Domain Routing (CIDR) block for the VPC"
}

variable "vpc_secondary_cidr_blocks" {
  description = "Additional CIDR blocks for VPC"
  type        = "list"
  default     = []
}

variable "aws_azs" {
  type        = "list"
  description = "Availability Zones to create VPC"
}

variable "private_subnets_cidr_blocks" {
  type        = "list"
  description = "CIDR Blocks for Private Subnet"
}

variable "public_subnets_cidr_blocks" {
  type        = "list"
  description = "CIDR Blocks for Private Subnet"
}

variable "data_subnets_cidr_blocks" {
  type        = "list"
  description = "CIDR Blocks for Data Subnet"
}

variable "new_private_subnets_cidr_blocks" {
  description = "CIDR blocks for the new private subnets"
  type        = "list"
}

variable "aws_region" {
  description = "aws region to create resources"
}

variable "az_count" {
  description = "Number of AZs"
}

variable "dataports" {
  type        = "list"
  description = "List of ports needed for data NACL"
}

variable "dataports_count" {
  description = "Number of ports needed for data NACL"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}
