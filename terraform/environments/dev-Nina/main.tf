locals {
  global_tags = {
    "${var.tag_prefix}:environment" = "${var.env_prefix}"
    "${var.tag_prefix}:application" = "${var.application_tag}"
    "terraform"                     = "true"
  }

  artifacts_s3_id             = "${data.terraform_remote_state.shared.artifacts_s3_id}"
  data_load_service_role_name = "${data.terraform_remote_state.shared.data_load_service_role_name}"
}

module "opa-release-setup" {
  source      = "../../modules/opa-release-setup"
  env_prefix  = "${var.env_prefix}"
  global_tags = "${local.global_tags}"
}

module "mstr-postinstall" {
  source                        = "../../modules/mstr-postinstall"
  env_prefix                    = "${var.env_prefix}"
  artifacts_s3_bucket           = "${local.artifacts_s3_id}"
  aws_region                    = "${var.aws_region}"
  global_tags                   = "${local.global_tags}"
  opa_api_source_code_s3_bucket = "${module.opa-api.opa_api_source_code_s3_bucket}"
  opa_api_source_code_s3_key    = "${module.opa-api.opa_api_source_code_s3_key}"
  dataloader_egress_sg_id       = "sg-0e098945190094661"
}

/*
# resource provisioner for MSTR instances
module "opa-mstr-aws" {
  source          = "../../modules/opa-mstr-aws"
  env_prefix      = "${var.env_prefix}"
  s3_artifacts_id = "${data.terraform_remote_state.shared.artifacts_s3_id}"

  #global_tags = "${var.global_tags}"
}
*/

module "opa-main" {
  source                        = "../../modules/opa-main"
  artifacts_s3_bucket           = "${local.artifacts_s3_id}"
  aws_region                    = "${var.aws_region}"
  env_prefix                    = "${var.env_prefix}"
  global_tags                   = "${local.global_tags}"
  opa_api_source_code_s3_bucket = "${module.opa-api.opa_api_source_code_s3_bucket}"
  opa_api_source_code_s3_key    = "${module.opa-api.opa_api_source_code_s3_key}"
}

module "opa-release" {
  source                          = "../../modules/opa-release"
  env_prefix                      = "${var.env_prefix}"
  deploy_opa_lambda_arn           = "${module.opa-main.deploy_opa_lambda_arn}"
  deploy_mstr_lambda_arn          = "${module.api.opa_mstr_migration_lambda_arn}"
  mstr_postinstall_lambda_arn     = "${module.mstr-postinstall.opa_mstr_postinstall_lambda_arn}"
  opa_master_lambda_arn           = "${module.api.opa_master_lambda_arn}"
  opa_release_s3_bucket           = "760182235631-opa-artifacts-opa"
  global_tags                     = "${local.global_tags}"
  opa_release_sns_topic_arn       = "${module.opa-release-setup.opa_release_sns_topic_arn}"
  opa_release_sns_role_arn        = "${module.opa-release-setup.opa_release_sns_role_arn}"
  artifacts_s3_bucket             = "760182235631-opa-artifacts-opa"
  opa_api_source_code_s3_bucket   = "${module.opa-api.opa_api_source_code_s3_bucket}"
  opa_api_source_code_s3_key      = "${module.opa-api.opa_api_source_code_s3_key}"
  opa_deploy_rw_schema_lambda_arn = "${module.api.opa_deploy_rw_schema_lambda_arn}"
}

/*
module "opa-mstr-d03" {
  source                    = "../../modules/opa-mstr"
  env_prefix                = "${var.env_prefix}"
  mstr_stack_name           = "env-139377"
  global_tags               = "${local.global_tags}"
  environmentName           = "opadev3-enterprise"
  opa_release_sns_topic_arn = "${module.opa-release-setup.opa_release_sns_topic_arn}"
}
*/

module "opa-mstr-d01" {
  source                    = "../../modules/opa-mstr"
  env_prefix                = "${var.env_prefix}"
  mstr_stack_name           = "env-164062"
  global_tags               = "${local.global_tags}"
  environmentName           = "opadev1-enterprise"
  opa_release_sns_topic_arn = "${module.opa-release-setup.opa_release_sns_topic_arn}"
}
