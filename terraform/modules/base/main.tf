locals {
  vpc_id                                = "${var.vpc_id}"
  vpc_cidr_block                        = "${var.vpc_cidr_block}"
  vpc_public_subnet_ids                 = "${var.vpc_public_subnet_ids}"
  vpc_private_subnet_ids                = "${var.vpc_private_subnet_ids}"
  subnet_new_private_subnet_ids         = "${var.subnet_new_private_subnet_ids}"
  subnet_new_private_subnet_cidr_blocks = "${var.subnet_new_private_subnet_cidr_blocks}"
  subnet_data_subnet_ids                = "${var.subnet_data_subnet_ids}"
  subnet_data_subnet_cidr_blocks        = "${var.subnet_data_subnet_cidr_blocks}"
  hybrid_subnet_cidr_blocks             = "${var.hybrid_subnet_cidr_blocks}"
  vpc_s3_endpoint_cidr_blocks           = "${var.vpc_s3_endpoint_cidr_blocks}"
  s3_artifacts_id                       = "${var.s3_artifacts_id}"
  s3_opa_logs_id                        = "${var.s3_opa_logs_id}"
  opa_release_s3_bucket                 = "${var.opa_release_s3_bucket}"
}

module "opa-main" {
  source                        = "../../modules/opa-main"
  artifacts_s3_bucket           = "${local.s3_artifacts_id}"
  aws_region                    = "${var.aws_region}"
  env_prefix                    = "${var.env_prefix}"
  opa_api_source_code_s3_bucket = "${module.opa-api.opa_api_source_code_s3_bucket}"
  opa_api_source_code_s3_key    = "${module.opa-api.opa_api_source_code_s3_key}"
  global_tags                   = "${var.global_tags}"
}

module "opa-app-elb" {
  source                = "../../modules/opa-app-elb"
  env_prefix            = "${var.env_prefix}"
  vpc_id                = "${local.vpc_id}"
  vpc_public_subnet_ids = "${local.vpc_public_subnet_ids}"
  s3_opa_logs_id        = "${local.s3_opa_logs_id}"
  ssl_cert_name         = "${var.ssl_cert_name}"
  global_tags           = "${var.global_tags}"
}

module "rds-instance-modifier" {
  source             = "../../modules/modify-rds-instance"
  is_prod            = "${var.is_prod}"
  tag_filters        = "{'aws:cloudformation:logical-id':'RDSMySQL', 'Environment':'${var.env_prefix}'}"
  rds_instance_class = "${var.mstr_rds_instance_class}"
}

module "update-ssm-agent" {
  source                               = "../schedule-instances-task"
  task_name                            = "update-ssm-agent"
  task_description                     = "For all instances in ssm, update agentVersion every Sundays at 2am in US East timezone"
  task_arn                             = "AWS-UpdateSSMAgent"
  maintenance_window_schedule_time     = "cron(0 2 ? * SUN *)"
  maintenance_window_schedule_timezone = "America/New_York"
  maintenance_window_schedule_duration = 2
  maintenance_window_schedule_cutoff   = 1
  env_prefix                           = "${var.env_prefix}"
}

# module "session-manager-settings" {
#   source = "../../modules/session-manager-settings"

#   s3_bucket_name            = "${local.s3_opa_logs_id}"
#   s3_key_prefix             = "ssm-session-manager-logs"
#   cloudwatch_log_group_name = "/ssm/session-manager-logs"
#   global_tags               = "${var.global_tags}"
# }

# Redshift egress security group
# Allows outbound traffic to data subnets
# Each redshift cluster's SG will then allow inbound traffic from this SG
resource "aws_security_group" "redshift_egress_sg" {
  name        = "${var.env_prefix}-redshift-egress-sg"
  description = "Security group for ${var.env_prefix} redshift egress"
  vpc_id      = "${local.vpc_id}"

  egress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["${local.subnet_data_subnet_cidr_blocks}"]
  }

  tags = "${merge(var.global_tags, map("Name", "${var.env_prefix}-redshift-egress-sg"))}"
}

module "dataloader" {
  source                            = "../../modules/dataloader"
  env_prefix                        = "${var.env_prefix}"
  global_tags                       = "${var.global_tags}"
  vpc_id                            = "${local.vpc_id}"
  private_subnet_ids                = "${local.subnet_new_private_subnet_ids}"
  vpc_cidr_block                    = "${local.vpc_cidr_block}"
  is_hybrid                         = "${!var.is_prod}"
  hybrid_subnet_cidr_blocks         = "${local.hybrid_subnet_cidr_blocks}"
  redshift_egress_security_group_id = "${aws_security_group.redshift_egress_sg.id}"
  ec2_instance_type                 = "${var.dataloader_ec2_instance_type}"
  autoscale_min                     = "${var.dataloader_autoscale_min}"
  autoscale_max                     = "${var.dataloader_autoscale_max}"
  elb_logs_bucket_id                = "${local.s3_opa_logs_id}"
  ca_private_key_ssm_param_name     = "${var.ca_private_key_ssm_param_name}"
  ca_public_cert_ssm_param_name     = "${var.ca_public_cert_ssm_param_name}"
  s3_bucket_id                      = "${var.dataloader_s3_bucket_id}"
}

# opa release
module "opa-release-setup" {
  source      = "../../modules/opa-release-setup"
  env_prefix  = "${var.env_prefix}"
  global_tags = "${var.global_tags}"
}

module "opa-release" {
  source                          = "../../modules/opa-release"
  env_prefix                      = "${var.env_prefix}"
  deploy_opa_lambda_arn           = "${module.opa-main.deploy_opa_lambda_arn}"
  deploy_mstr_lambda_arn          = "${module.api.opa_mstr_migration_lambda_arn}"
  mstr_postinstall_lambda_arn     = "${module.mstr-postinstall.opa_mstr_postinstall_lambda_arn}"
  opa_master_lambda_arn           = "${module.api.opa_master_lambda_arn}"
  opa_deploy_rw_schema_lambda_arn = "${module.api.opa_deploy_rw_schema_lambda_arn}"
  opa_release_s3_bucket           = "${local.opa_release_s3_bucket}"
  global_tags                     = "${var.global_tags}"
  opa_release_sns_topic_arn       = "${module.opa-release-setup.opa_release_sns_topic_arn}"
  opa_release_sns_role_arn        = "${module.opa-release-setup.opa_release_sns_role_arn}"
  artifacts_s3_bucket             = "${local.s3_artifacts_id}"
  opa_api_source_code_s3_bucket   = "${module.opa-api.opa_api_source_code_s3_bucket}"
  opa_api_source_code_s3_key      = "${module.opa-api.opa_api_source_code_s3_key}"
}
