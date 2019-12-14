locals {
  vpc_id                           = "${module.base-shared.vpc_id}"
  vpc_cidr_block                   = "${module.base-shared.vpc_cidr_block}"
  vpc_public_subnet_ids            = "${module.base-shared.vpc_public_subnet_ids}"
  vpc_private_subnet_ids           = "${module.base-shared.vpc_private_subnet_ids}"
  subnet_data_subnet_ids           = "${module.base-shared.subnet_data_subnet_ids}"
  subnet_data_subnet_cidr_blocks   = "${module.base-shared.subnet_data_subnet_cidr_blocks}"
  hybrid_subnet_cidr_blocks        = "${module.base-shared.hybrid_subnet_cidr_blocks}"
  vpc_s3_endpoint_cidr_blocks      = "${module.base-shared.vpc_s3_endpoint_cidr_blocks}"
  s3_opa_logs_id                   = "${module.base-shared.s3_opa_logs_id}"
  s3_artifacts_id                  = "${module.base-shared.artifacts_s3_id}"
  s3_client_data_id                = "${module.base-shared.s3_client_data_id}"
  s3_registry_data_id              = "${module.base-shared.s3_registry_data_id}"
  s3_mstr_backups_id               = "${module.base-shared.s3_mstr_backups_id}"
  orchestration_arn                = "${module.base-shared.orchestration_arn}"
  appstream_sg_id                  = "${module.base-shared.appstream_sg_id}"
  ca_public_cert_ssm_param_name    = "${module.base-shared.ca_public_cert_ssm_param_name}"
  ca_private_key_ssm_param_name    = "${module.base-shared.ca_private_key_ssm_param_name}"
  redshift_service_access_role_arn = "${module.base-shared.redshift_service_access_role_arn}"
  data_load_service_role_name      = "${module.base-shared.data_load_service_role_name}"
  account_id                       = "${data.aws_caller_identity.current_identity.account_id}"
  opa_release_s3_bucket            = "${module.base-shared.artifacts_s3_id}"

  global_tags = {
    "optum:environment" = "${var.env_prefix}"
    "optum:application" = "OPA"
    "terraform"         = "true"
  }
}

data "aws_caller_identity" "current_identity" {}

module "base-shared" {
  source = "../../modules/base-shared"

  # environment setup
  is_prod                = "false"
  aws_region             = "${var.aws_region}"
  aws_replication_region = "${var.aws_replication_region}"
  env_prefix             = "${var.env_prefix}"
  aws_profile            = "saml"

  # s3
  artifacts_bucket_name_suffix     = "opa-artifacts-ci"
  client_data_bucket_name_suffix   = "opa-client-data-ci"
  registry_data_bucket_name_suffix = "opa-registry-data-ci"
  tag_name_identifier              = "nonprod-ci"
  flat_files_bucket_name_suffix    = "opa-flat-files-ci"

  # network - we are only allowed one hybrid network by Optum so turn hybrid off
  is_hybrid_network           = "false"
  network_name                = "nonprod-ci"
  vpc_cidr_block              = "10.250.166.0/24"
  public_subnets_cidr_blocks  = ["10.250.166.0/27", "10.250.166.32/27"]
  private_subnets_cidr_blocks = ["10.250.166.64/27", "10.250.166.96/27"]
  data_subnets_cidr_blocks    = ["10.250.166.160/27", "10.250.166.128/27"]
  dataports_count             = 3
  dataports                   = ["5439", "5432", "3306"]

  # tagging
  global_tags = "${local.global_tags}"
}

module "base" {
  source = "../../modules/base"

  # environment setup
  is_prod                = "false"
  aws_region             = "${var.aws_region}"
  aws_replication_region = "${var.aws_replication_region}"
  env_prefix             = "${var.env_prefix}"

  # vpc
  vpc_id                         = "${local.vpc_id}"
  vpc_cidr_block                 = "${local.vpc_cidr_block}"
  vpc_public_subnet_ids          = "${local.vpc_public_subnet_ids}"
  vpc_private_subnet_ids         = "${local.vpc_private_subnet_ids}"
  subnet_data_subnet_ids         = "${local.subnet_data_subnet_ids}"
  subnet_data_subnet_cidr_blocks = "${local.subnet_data_subnet_cidr_blocks}"
  hybrid_subnet_cidr_blocks      = "${local.hybrid_subnet_cidr_blocks}"
  vpc_s3_endpoint_cidr_blocks    = "${local.vpc_s3_endpoint_cidr_blocks}"

  # api
  api_id                      = "TODO"
  data_load_service_role_name = "${local.data_load_service_role_name}"

  # s3
  s3_opa_logs_id      = "${local.s3_opa_logs_id}"
  s3_artifacts_id     = "${local.s3_artifacts_id}"
  s3_client_data_id   = "${local.s3_client_data_id}"
  s3_registry_data_id = "${local.s3_registry_data_id}"
  s3_mstr_backups_id  = "${local.s3_mstr_backups_id}"

  # mstr
  orchestration_arn       = "${local.orchestration_arn}"
  mstr_rds_instance_class = "db.t3.medium"
  ssl_cert_name           = "devcloud"

  # alarms
  alarms_email = "opa-aws-dev-alerts@uhg.flowdock.com"

  # tagging
  global_tags = "${local.global_tags}"

  # dataloader
  dataloader_autoscale_min      = "1"
  dataloader_autoscale_max      = "1"
  dataloader_ec2_instance_type  = "t2.nano"
  ca_public_cert_ssm_param_name = "${local.ca_public_cert_ssm_param_name}"
  ca_private_key_ssm_param_name = "${local.ca_private_key_ssm_param_name}"
  dataloader_s3_bucket_id       = "${local.s3_registry_data_id}"

  # LINK
  link_service_role_arn = "${module.base-shared.link_service_role_arn}"

  # opa-release
  opa_release_s3_bucket = "${local.opa_release_s3_bucket}"

  # Notifications
  ci_email             = "opa-aws-notify@uhg.flowdock.com"
  opa_operations_email = "opa-aws-notify@uhg.flowdock.com"
}
