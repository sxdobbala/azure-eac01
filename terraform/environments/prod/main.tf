locals {
  vpc_id                                = "${data.terraform_remote_state.shared.vpc_id}"
  vpc_cidr_block                        = "${data.terraform_remote_state.shared.vpc_cidr_block}"
  vpc_public_subnet_ids                 = "${data.terraform_remote_state.shared.vpc_public_subnet_ids}"
  vpc_private_subnet_ids                = "${data.terraform_remote_state.shared.vpc_private_subnet_ids}"
  subnet_data_subnet_ids                = "${data.terraform_remote_state.shared.subnet_data_subnet_ids}"
  subnet_data_subnet_cidr_blocks        = "${data.terraform_remote_state.shared.subnet_data_subnet_cidr_blocks}"
  subnet_new_private_subnet_ids         = "${data.terraform_remote_state.shared.subnet_new_private_subnet_ids}"
  subnet_new_private_subnet_cidr_blocks = "${data.terraform_remote_state.shared.subnet_new_private_subnet_cidr_blocks}"
  hybrid_subnet_cidr_blocks             = ["127.0.0.1/32"]
  vpc_s3_endpoint_cidr_blocks           = "${data.terraform_remote_state.shared.vpc_s3_endpoint_cidr_blocks}"
  s3_opa_logs_id                        = "${data.terraform_remote_state.shared.s3_opa_logs_id}"
  s3_artifacts_id                       = "${data.terraform_remote_state.shared.artifacts_s3_id}"
  s3_client_data_id                     = "${data.terraform_remote_state.shared.s3_client_data_id}"
  s3_registry_data_id                   = "${data.terraform_remote_state.shared.s3_registry_data_id}"
  s3_mstr_backups_id                    = "${data.terraform_remote_state.shared.s3_mstr_backups_id}"
  orchestration_arn                     = "${data.terraform_remote_state.shared.orchestration_arn}"
  appstream_sg_id                       = "${data.terraform_remote_state.shared.appstream_sg_id}"
  ca_public_cert_ssm_param_name         = "${data.terraform_remote_state.shared.ca_public_cert_ssm_param_name}"
  ca_private_key_ssm_param_name         = "${data.terraform_remote_state.shared.ca_private_key_ssm_param_name}"
  redshift_service_access_role_arn      = "${data.terraform_remote_state.shared.redshift_service_access_role_arn}"
  data_load_service_role_name           = "${data.terraform_remote_state.shared.data_load_service_role_name}"
  link_service_role_arn                 = "${data.terraform_remote_state.shared.link_service_role_arn}"
  account_id                            = "${data.aws_caller_identity.current_identity.account_id}"
  opa_release_s3_bucket                 = "760182235631-opa-artifacts-opa"

  global_tags = {
    "optum:environment" = "${var.env_prefix}"
    "optum:application" = "OPA"
    "terraform"         = "true"
  }
}

data "aws_caller_identity" "current_identity" {}

module "base" {
  source = "../../modules/base"

  # environment setup
  is_prod                = "true"
  aws_region             = "${var.aws_region}"
  aws_replication_region = "${var.aws_replication_region}"
  env_prefix             = "${var.env_prefix}"

  # vpc
  vpc_id                                = "${local.vpc_id}"
  vpc_cidr_block                        = "${local.vpc_cidr_block}"
  vpc_public_subnet_ids                 = "${local.vpc_public_subnet_ids}"
  vpc_private_subnet_ids                = "${local.vpc_private_subnet_ids}"
  subnet_data_subnet_ids                = "${local.subnet_data_subnet_ids}"
  subnet_data_subnet_cidr_blocks        = "${local.subnet_data_subnet_cidr_blocks}"
  subnet_new_private_subnet_ids         = "${local.subnet_new_private_subnet_ids}"
  subnet_new_private_subnet_cidr_blocks = "${local.subnet_new_private_subnet_cidr_blocks}"
  hybrid_subnet_cidr_blocks             = "${local.hybrid_subnet_cidr_blocks}"
  vpc_s3_endpoint_cidr_blocks           = "${local.vpc_s3_endpoint_cidr_blocks}"

  # api
  api_id                      = "egx0cbre0l"
  data_load_service_role_name = "${local.data_load_service_role_name}"

  # s3
  s3_opa_logs_id      = "${local.s3_opa_logs_id}"
  s3_artifacts_id     = "${local.s3_artifacts_id}"
  s3_client_data_id   = "${local.s3_client_data_id}"
  s3_registry_data_id = "${local.s3_registry_data_id}"
  s3_mstr_backups_id  = "${local.s3_mstr_backups_id}"

  # mstr
  orchestration_arn       = "${local.orchestration_arn}"
  mstr_rds_instance_class = "db.r4.large"
  ssl_cert_name           = "cloud2"

  # alarms
  alarms_email = "opa-aws-dev-alerts@uhg.flowdock.com"

  # tagging
  global_tags = "${local.global_tags}"

  # dataloader
  dataloader_autoscale_min      = "2"
  dataloader_autoscale_max      = "2"
  dataloader_ec2_instance_type  = "r4.large"
  ca_public_cert_ssm_param_name = "${local.ca_public_cert_ssm_param_name}"
  ca_private_key_ssm_param_name = "${local.ca_private_key_ssm_param_name}"
  dataloader_s3_bucket_id       = "${local.s3_registry_data_id}"

  # LINK
  link_service_role_arn = "${local.link_service_role_arn}"

  # opa-release
  opa_release_s3_bucket = "${local.opa_release_s3_bucket}"

  # Notifications
  ci_email             = "opa-aws-notify@uhg.flowdock.com"
  opa_operations_email = "opa-aws-notify@uhg.flowdock.com"
}
