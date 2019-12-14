variable "alarms_email" {}

variable "ec2_instanceIds" {
  type = "list"
}

variable "load_balancers" {
  type = "list"
}

variable "redshift_clusterIdentifiers" {
  type = "list"
}

variable "rds_instanceIds" {
  type = "list"
}

variable "thresholds" {
  type = "map"
}

variable "env_prefix" {
  description = "AWS environment you are deploying to. Will be appended to SNS topic and alarm name. (e.g. dev, stage, prod)"
}

variable "opa_api_source_code_s3_bucket" {
  description = "S3 bucket with API lambda source code"
}

variable "opa_api_source_code_s3_key" {
  description = "S3 key with API lambda source code"
}
