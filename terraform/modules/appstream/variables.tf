variable "vpc_id" {
  description = "ID of VPC"
}

variable "vpc_cidr_blocks" {
  type        = "list"
  description = "List of CIDR Blocks for vpc"
}

variable "https_cidr_blocks" {
  type        = "list"
  description = "CIDR Blocks for HTTPS"
  default     = ["127.0.0.1/32"]
}

variable "egress_port_numbers" {
  type        = "list"
  description = "List of Port Numbers to Set up Egress On"
  default     = [""]
}

variable "list_of_aws_azs" {
  type        = "list"
  description = "List of AWS AZ's to run in"
}

variable "list_of_cidr_block_for_private_subnets" {
  type        = "list"
  description = "List of CIDR Blocks for private subnets to run in"
}

variable "image_arn" {
  type        = "string"
  description = "ARN of appstream image"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}

variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
  default     = ""
}
