module "opa-main" {
  source                        = "../../modules/opa-main"
  artifacts_s3_bucket           = "${data.terraform_remote_state.shared.artifacts_s3_id}"
  aws_region                    = "${var.aws_region}"
  env_prefix                    = "${var.env_prefix}"
  global_tags                   = "${local.global_tags}"
  opa_api_source_code_s3_bucket = "${module.opa-api.opa_api_source_code_s3_bucket}"
  opa_api_source_code_s3_key    = "${module.opa-api.opa_api_source_code_s3_key}"
}

module "opa-release-setup" {
  source      = "../../modules/opa-release-setup"
  env_prefix  = "${var.env_prefix}"
  global_tags = "${local.global_tags}"
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
