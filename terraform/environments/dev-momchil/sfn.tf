module "mstr-postinstall" {
  source                        = "../../modules/mstr-postinstall"
  env_prefix                    = "${var.env_prefix}"
  artifacts_s3_bucket           = "${data.terraform_remote_state.shared.artifacts_s3_id}"
  aws_region                    = "${var.aws_region}"
  opa_api_source_code_s3_bucket = "${module.opa-api.opa_api_source_code_s3_bucket}"
  opa_api_source_code_s3_key    = "${module.opa-api.opa_api_source_code_s3_key}"
  dataloader_egress_sg_id       = "sg-0e098945190094661"
  global_tags                   = "${local.global_tags}"
}

module "mstr-environment" {
  source                      = "../../modules/mstr-environment"
  env_prefix                  = "${var.env_prefix}"
  vpc_id                      = "vpc-0a44c492a7e854b71"
  artifacts_s3_bucket         = "${data.terraform_remote_state.shared.artifacts_s3_id}"
  opa_mstr_aws_archive_s3_key = "${module.opa-mstr-aws.opa_mstr_aws_archive_s3_key}"

  opa_release_sns_topic_arn = "arn:aws:sns:us-east-1:760182235631:dev-momchil-opa-release-sns-topic"

  opa_mstr_stack_lambda_arn     = "${module.api.opa_mstr_stack_lambda_arn}"
  opa_tf_runner_lambda_arn      = "${module.api.opa_tf_runner_lambda_arn}"
  opa_mstr_backup_lambda_arn    = "${module.api.opa_mstr_backup_lambda_arn}"
  opa_api_source_code_s3_bucket = "${module.opa-api.opa_api_source_code_s3_bucket}"
  opa_api_source_code_s3_key    = "${module.opa-api.opa_api_source_code_s3_key}"

  global_tags = "${local.global_tags}"
}

module "client-onboarding" {
  source     = "../../modules/client-onboarding"
  env_prefix = "${var.env_prefix}"

  opa_master_lambda_arn                   = "${module.api.opa_master_lambda_arn}"
  opa_client_onboarding_lambda_arn        = "${module.api.opa_client_onboarding_lambda_arn}"
  opa_client_redshift_security_lambda_arn = "${module.api.opa_client_redshift_security_lambda_arn}"
  opa_tf_runner_lambda_arn                = "${module.api.opa_tf_runner_lambda_arn}"
  opa_deploy_rw_schema_lambda_arn         = "${module.api.opa_deploy_rw_schema_lambda_arn}"
  opa_smoke_test_lambda_arn               = "${module.api.opa_smoke_test_lambda_arn}"
  opa_client_env_move_lambda_arn          = "${module.api.opa_client_env_move_lambda_arn}"
  opa_timezone_change_lambda_arn          = "${module.api.opa_timezone_change_lambda_arn}"

  vpc_id                      = "vpc-0a44c492a7e854b71"
  artifacts_s3_bucket         = "${data.terraform_remote_state.shared.artifacts_s3_id}"
  opa_mstr_aws_archive_s3_key = "${module.opa-mstr-aws.opa_mstr_aws_archive_s3_key}"
  opa_release_sns_topic_arn   = "arn:aws:sns:us-east-1:760182235631:dev-momchil-opa-release-sns-topic"

  global_tags = "${local.global_tags}"
}

resource "aws_sns_topic" "ci-sns-topic" {
  name = "${var.env_prefix}-ci-sns-topic"

  provisioner "local-exec" {
    # Hack to subscribe email to SNS topic.
    # Email subscription is not supported because the endpoint needs to be authorized and does not generate an ARN until the target email address has been validated.
    # Subscription policy can be updated later (e.g. get only messages with ExecutionStatus as "failed").
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${local.ci_email}"
  }
}

resource "aws_sns_topic" "opa-operations-sns-topic" {
  name = "${var.env_prefix}-opa-operations-sns-topic"

  provisioner "local-exec" {
    # Hack to subscribe email to SNS topic.
    # Email subscription is not supported because the endpoint needs to be authorized and does not generate an ARN until the target email address has been validated.
    # Subscription policy can be updated later (e.g. get only messages with ExecutionStatus as "failed").
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${local.opa_operations_email}"
  }
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

  global_tags = "${local.global_tags}"
}
