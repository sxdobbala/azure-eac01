variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/stg/prod or dev-joe"
  default     = ""
}

variable vpc_id {
  description = "VPC id"
}

variable vpc_public_subnet_ids {
  description = "VPC public subnet ids"
  type        = "list"
}

variable "s3_opa_logs_id" {
  description = "OPA logs S3 bucket id"
}

variable "ssl_cert_name" {
  description = "Name of the SSL certificate. e.g. devcloud/qacloud"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}
