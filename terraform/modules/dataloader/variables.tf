variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}

variable "app_name" {
  description = "Name of elastic beanstalk application that already exists"
  default     = "dataloader"
}

variable "solution_stack_name" {
  description = "Solution stack to base your environment off of. Example stacks can be found in the Amazon API documentation: https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/concepts.platforms.html"
  default     = "64bit Amazon Linux 2018.03 v2.9.2 running Java 8"

  # TODO: OAP-9381 Dataloader infra should not revert solution stack version
  # We need to figure out a better way to avoid rollback since we have automatic updates enabled for minor versions.
}

variable "environment_type" {
  description = "Choose environment type between SingleInstance or LoadBalanced"
  default     = "LoadBalanced"
}

variable "elb_type" {
  description = "Choose load balancer type between classic, application or network"
  default     = "application"
}

variable "autoscale_min" {
  description = "Choose the minimum instances to be used by load balancer"
  default     = 1
}

variable "autoscale_max" {
  description = "Choose the maximum instances to be used by load balancer"
  default     = 2
}

variable vpc_id {
  description = "VPC id"
}

variable "private_subnet_ids" {
  description = "IDs for the private subnets. Both EC2 and ELB will be hosted in private subnets."
  type        = "list"
}

variable "elb_ssl_policy" {
  description = "Specify a security policy to apply to the listener. This option is only applicable to environments with an application load balancer."
  default     = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
}

variable "healthcheck_url" {
  description = "The path to which to send health check requests"
  default     = "/health"
}

variable "redshift_egress_security_group_id" {
  description = "Security group that allows outbound access to data subnets on RedShift port"
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
}

variable "hybrid_subnet_cidr_blocks" {
  description = "List of CIDR blocks that identify hybrid subnet. Generally 10.0.0.0/8"
  type        = "list"
  default     = []
}

variable "is_hybrid" {
  default = "false"
}

variable "ec2_instance_type" {
  description = "The instance type used to run the application"
  default     = "t2.micro"
}

variable "is_https_enabled" {
  description = "Uses https listener if enabled. Default is true"
  default     = "true"
}

variable "is_http_enabled" {
  description = "Uses http listener if enabled. Default is false."
  default     = "false"
}

variable "elb_http_port" {
  description = "Port number for http listener on ELB"
  default     = "8080"
}

variable "elb_https_port" {
  description = "Port number for https listener on ELB"
  default     = "443"
}

variable "elb_logs_bucket_id" {
  description = "Id of the S3 bucket to upload ELB access logs to"
}

variable "ca_public_cert_ssm_param_name" {
  description = "SSM param name for CA public cert"
}

variable "ca_private_key_ssm_param_name" {
  description = "SSM param name for CA private key"
}

variable "s3_bucket_id" {
  description = "Id of the S3 bucket used for temp storage"
}
