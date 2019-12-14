variable "hybrid_subnet_cidr_blocks" {
  type    = "list"
  default = []
}

variable "is_hybrid" {
  default = "false"
}

variable "master_username" {}

variable "vpc_id" {}

variable "label" {
  description = "Unique Environment Label (sets cluster name as well as labels for other resources)"
}

# TODO: make this optional in redshift-with-security module; underlying EAC defaults to empty
variable "snapshot_identifier" {}

variable "final_snapshot_identifier" {
  default = ""
}

variable "cluster_type" {}

variable "instance_type" {}

variable "number_of_nodes" {}

variable "database_name" {
  description = "The name of the first database to be created when the cluster is created."
}

variable "aws_az" {}

variable "subnet_cidr_blocks" {
  type = "list"
}

variable "subnet_ids" {
  type = "list"
}

variable "enhanced_vpc_routing" {
  description = "The port on which the DB accepts connections"
  default     = "true"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}

variable redshift_iam_roles_arn {
  description = "IAM roles list for Redshift"
  type        = "list"
  default     = [""]
}

variable "vpc_s3_endpoint_cidr_blocks" {
  type = "list"

  description = "CIDR Blocks of the VPC Endpoint for S3"
}

variable "wlm_json_configuration" {
  description = "WLM json configuration. See https://docs.aws.amazon.com/redshift/latest/mgmt/workload-mgmt-config.html"
  default     = "[{\"queue_type\":\"auto\",\"auto_wlm\": true, \"priority\": \"normal\", \"query_group\":[\"MSTR*\"],\"query_group_wild_card\":1,\"user_group\":[],\"user_group_wild_card\":0, \"concurrency_scaling\":\"auto\"},{\"queue_type\":\"auto\",\"auto_wlm\": true, \"priority\": \"high\", \"query_group\":[],\"query_group_wild_card\":0,\"user_group\":[],\"user_group_wild_card\":0},{\"short_query_queue\":true}]"
}

variable "appstream_sg_id" {
  description = "appstream security group ID for ingress"
}

variable "redshift_egress_sg_id" {
  description = "redshift egress security group ID for ingress"
}
