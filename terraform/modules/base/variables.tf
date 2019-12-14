variable "is_prod" {
  description = "Flag used to determine whether to create prod or non-prod resources"
}

variable "aws_region" {
  description = "AWS region to create resources"
}

variable "aws_replication_region" {
  description = "AWS region for replication"
}

variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

# TAGGING

variable "global_tags" {
  description = "Global tags to be applied to all resources"
  type        = "map"
}

# NETWORK

variable "vpc_id" {
  description = "ID of the VPC"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
}

variable "vpc_public_subnet_ids" {
  description = "IDs for the public subnets of the VPC"
  type        = "list"
}

variable "vpc_private_subnet_ids" {
  description = "IDs for the private subnets of the VPC"
  type        = "list"
}

variable "subnet_data_subnet_ids" {
  description = "IDs for the data subnets of the VPC"
  type        = "list"
}

variable "subnet_data_subnet_cidr_blocks" {
  description = "CIDR blocks for the data subnets of the VPC"
  type        = "list"
}

variable "subnet_new_private_subnet_ids" {
  description = "IDs for the new private subnets of the VPC"
  type        = "list"
}

variable "subnet_new_private_subnet_cidr_blocks" {
  description = "CIDR blocks for the  new private subnets of the VPC"
  type        = "list"
}

variable "hybrid_subnet_cidr_blocks" {
  description = "CIDR blocks for the hybrid subnets of the VPC"
  type        = "list"
}

variable "vpc_s3_endpoint_cidr_blocks" {
  description = "CIDR blocks for the S3 endpoint of the VPC"
  type        = "list"
}

# API

variable "api_id" {
  description = "ID of the API"
}

variable "data_load_service_role_name" {
  description = "The name of the Data Load Service role"
}

# S3

variable "s3_opa_logs_id" {
  description = "S3 bucket for OPA logs"
}

variable "s3_artifacts_id" {
  description = "S3 bucket for OPA artifacts"
}

variable "s3_client_data_id" {
  description = "S3 bucket for OPA client data"
}

variable "s3_registry_data_id" {
  description = "S3 bucket for OPA registry data"
}

variable "s3_mstr_backups_id" {
  description = "S3 bucket for opa-mstr-backups"
}

# MSTR

variable "orchestration_arn" {
  description = "ARN for the SNS topic used by MSTR to orchestrate"
}

variable "mstr_rds_instance_class" {
  description = "Target instance class when resizing the RDS mySQL instances created by MSTR."
}

variable "ssl_cert_name" {
  description = "Name of the SSL certificate to install on the MSTR load balancer"
  default     = "wildcardTrialCloud2020"
}

# BILLING & ALARMS

variable "alarms_email" {
  description = "Triggered alarms will be notified to this email address"
}

variable "alarm_thresholds" {
  description = "Threshold values for the various critical alarms"
  type        = "map"

  default = {
    ec2 = {
      cpu_utilization = "90"
    }

    load_balancer = {
      rejected_connection_count = "0"
      unhealthy_host_count      = "0"
    }

    redshift = {
      cpu_utilization           = "90"
      percentage_diskSpace_used = "80"
    }

    rds = {
      burst_balance   = "40"
      cpu_utilization = "90"
    }

    cost = {
      monthly_cost_threshold = "2000"
      ec2_budget             = "1200"
      rds_budget             = "1000"
      redshift_budget        = "200"
    }
  }
}

# Dataloader
variable "dataloader_autoscale_min" {
  description = "Choose the minimum instances to be used by load balancer"
  default     = 1
}

variable "dataloader_autoscale_max" {
  description = "Choose the maximum instances to be used by load balancer"
  default     = 1
}

variable "dataloader_ec2_instance_type" {
  description = "The instance type used to run the application"
  default     = "t2.micro"
}

variable "ca_public_cert_ssm_param_name" {
  description = "SSM param name for CA public cert"
}

variable "ca_private_key_ssm_param_name" {
  description = "SSM param name for CA private key"
}

variable "dataloader_s3_bucket_id" {
  description = "Id of the S3 bucket used for temp storage"
}

# LINK
variable "link_service_role_arn" {
  description = "ARN of the role the LINK team is using to send/receive SQS messages"
}

variable "opa_release_s3_bucket" {
  description = "S3 artifacts bucket contains opa-releases package"
}

# Notifications
variable "ci_email" {
  description = "Continuous Integration (CI) updates will be notified to this email address"
}

variable "opa_operations_email" {
  description = "OPA operations (e.g. client management workflow updates, etc.) will be notified to this email address"
}
