data "aws_caller_identity" "current_identity" {}

data "aws_region" "current_region" {}

variable "vpc_id" {}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = "list"
}

variable "hybrid_cidr_block" {
  description = "CIDR block for the hybrid network"
  type        = "list"
}

variable data_subnet_ids {
  description = "VPC data subnet ids"
  type        = "list"
}

variable "aws_region" {
  description = "DEPRECATED. AWS Region is inherited from parent module."
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "DEPRECATED. AWS Profile is inherited from parent module."
  default     = ""
}

variable "database_identifier" {
  description = "Must be unique for all DB instances per AWS account, per region"
}

variable "engine" {
  description = "Database engine to use for the instance"
}

variable "engine_version" {
  description = "Database engine version to use for the instance"
}

variable "instance_class" {
  description = "Instance class to use for this instance"
}

variable "allocated_storage" {
  description = "The amount of storage in GB allocated to the database instance"
  default     = 50
}

variable "instance_port" {
  description = "The port on which the DB accepts connections"
}

variable "database_name" {
  description = "The name of the primary database to create on the instance"
}

variable "master_username" {
  description = "The name of the primary database to create on the instance"
}

variable "parameter_group_family" {
  description = "The name of the parameter group family to use with this instance"
}

variable "kms_key_id_arn" {
  description = "The ARN for the KMS encryption key.When None specified, AWS managed key is used for SSE"
  default     = ""
}

variable "iam_auth_enabled" {
  description = "Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled"
  default     = true
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  default     = "3"
}

variable "backup_window" {
  description = "Backup window during which automated backups are created if automated backups are enabled using the BackupRetentionPeriod parameter. In UTC"
  default     = "06:00-08:00"
}

variable "maintenance_window" {
  description = "Weekly time range during which system maintenance can occur, in UTC"
  default     = "sat:08:00-sat:10:00"
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window"
  default     = true
}

variable "apply_changes_immediately" {
  description = "Specifies whether any cluster modifications are applied immediately, or during the next maintenance window"
  default     = true
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB cluster is deleted"
  default     = false
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance"
  default     = 1
}

variable "multi_az" {
  description = "Whether or not the RDS instance support multiple availability zones"
  default     = false
}

# Note: event_categories is a String and not list. Terrafrom doesn't like heterogeneous types in a map
variable "event_subscription_cluster_config" {
  description = "Event subscription cluster configuration.When enabled SNS topic is must "
  type        = "map"

  default = {
    "enable"           = false
    "name-prefix"      = "rds-cluster-event-sub"
    "sns_topic_arn"    = ""
    "event_categories" = "failover,notification"
  }
}

# Note: event_categories is a String and not list. Terrafrom doesn't like heterogeneous types in a map
variable "event_subscription_instances_config" {
  description = "Event subscription instance configuration.When enabled SNS topic is must"
  type        = "map"

  default = {
    "enable"           = false
    "name-prefix"      = "rds-instance-event-sub"
    "sns_topic_arn"    = ""
    "event_categories" = "availability,backup,configuration change,creation,deletion,failover,failure,low storage,maintenance,notification,read replica,recovery"
  }
}

# Note: event_categories is a String and not list. Terrafrom doesn't like heterogeneous types 
variable "event_subscription_parametergroup_config" {
  description = "Event subscription parametergroup configuration.When enabled SNS topic is must"
  type        = "map"

  default = {
    "enable"           = false
    "name-prefix"      = "rds-parametergroup-event-sub"
    "sns_topic_arn"    = ""
    "event_categories" = "configuration change"
  }
}

variable "tag_name_identifier" {
  description = "Unique tag name identifier for all AWS resources that are grouped together"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}

variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}
