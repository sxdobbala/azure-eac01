# resource provisioner for MSTR instances
module "opa-mstr-aws" {
  source          = "../../modules/opa-mstr-aws"
  env_prefix      = "${var.env_prefix}"
  s3_artifacts_id = "${local.s3_artifacts_id}"

  #global_tags = "${var.global_tags}"
}

module "mstr-environment" {
  source                      = "../../modules/mstr-environment"
  env_prefix                  = "${var.env_prefix}"
  vpc_id                      = "${var.vpc_id}"
  artifacts_s3_bucket         = "${var.s3_artifacts_id}"
  opa_mstr_aws_archive_s3_key = "${module.opa-mstr-aws.opa_mstr_aws_archive_s3_key}"
  opa_release_sns_topic_arn   = "${module.opa-release-setup.opa_release_sns_topic_arn}"

  opa_mstr_stack_lambda_arn     = "${module.api.opa_mstr_stack_lambda_arn}"
  opa_mstr_backup_lambda_arn    = "${module.api.opa_mstr_backup_lambda_arn}"
  opa_tf_runner_lambda_arn      = "${module.api.opa_tf_runner_lambda_arn}"
  opa_api_source_code_s3_bucket = "${module.opa-api.opa_api_source_code_s3_bucket}"
  opa_api_source_code_s3_key    = "${module.opa-api.opa_api_source_code_s3_key}"

  global_tags = "${var.global_tags}"
}

module "client-onboarding" {
  source     = "../../modules/client-onboarding"
  env_prefix = "${var.env_prefix}"

  opa_master_lambda_arn                   = "${module.api.opa_master_lambda_arn}"
  opa_client_onboarding_lambda_arn        = "${module.api.opa_client_onboarding_lambda_arn}"
  opa_client_redshift_security_lambda_arn = "${module.api.opa_client_redshift_security_lambda_arn}"
  opa_deploy_rw_schema_lambda_arn         = "${module.api.opa_deploy_rw_schema_lambda_arn}"
  opa_smoke_test_lambda_arn               = "${module.api.opa_smoke_test_lambda_arn}"
  opa_tf_runner_lambda_arn                = "${module.api.opa_tf_runner_lambda_arn}"
  opa_client_env_move_lambda_arn          = "${module.api.opa_client_env_move_lambda_arn}"
  opa_timezone_change_lambda_arn          = "${module.api.opa_timezone_change_lambda_arn}"

  vpc_id                      = "${var.vpc_id}"
  artifacts_s3_bucket         = "${var.s3_artifacts_id}"
  opa_mstr_aws_archive_s3_key = "${module.opa-mstr-aws.opa_mstr_aws_archive_s3_key}"
  opa_release_sns_topic_arn   = "${module.opa-release-setup.opa_release_sns_topic_arn}"

  global_tags = "${var.global_tags}"
}

module "client-management" {
  source     = "../../modules/client-management"
  env_prefix = "${var.env_prefix}"

  mstr_backup_sfn_arn              = "${module.mstr-environment.mstr_backup_sfn_arn}"
  mstr_environment_create_sfn_arn  = "${module.mstr-environment.mstr_environment_create_sfn_arn}"
  mstr_environment_destroy_sfn_arn = "${module.mstr-environment.mstr_environment_destroy_sfn_arn}"
  opa_release_sfn_arn              = "${module.opa-release.opa_release_sfn_arn}"
  client_onboarding_sfn_arn        = "${module.client-onboarding.client_onboarding_sfn_arn}"
  client_stack_rotation_sfn_arn    = "${module.client-onboarding.client_stack_rotation_sfn_arn}"
  ci_sns_topic                     = "${aws_sns_topic.ci-sns-topic.arn}"
  opa_operations_sns_topic         = "${aws_sns_topic.opa-operations-sns-topic.arn}"

  global_tags = "${var.global_tags}"
}
