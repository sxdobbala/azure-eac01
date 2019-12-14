locals {
  # each api method should have its own environment vars section
  environment_vars = {
    OPA_MASTER_HOST           = "${module.opa-master.opa_rds_host}"
    OPA_MASTER_PORT           = "${module.opa-master.opa_rds_port}"
    OPA_MASTER_DATABASE       = "${module.opa-master.opa_rds_database_name}"
    OPA_MASTER_USER           = "${module.opa-master.opa_rds_username}"
    OPA_MASTER_PASSWORD_KEY   = "${module.opa-master.opa_rds_password_key}"
    OPA_RELEASE_SNS_ROLE_ARN  = "${module.opa-release-setup.opa_release_sns_role_arn}"
    OPA_RELEASE_SNS_TOPIC_ARN = "${module.opa-release-setup.opa_release_sns_topic_arn}"
    ENV_PREFIX                = "${var.env_prefix}"
    ARTIFACTS_BUCKET          = "${var.s3_artifacts_id}"
    MSTR_BACKUPS_BUCKET       = "${var.s3_mstr_backups_id}"
    TF_BACKEND_BUCKET         = "${var.is_prod == "true" ? "029620356096-tfstate-prodoptumopa" : "760182235631-tfstate-nonprodoptumopa"}"
    TF_BACKEND_TABLE          = "${var.is_prod == "true" ? "029620356096-tflock-prodoptumopa" : "760182235631-tflock-nonprodoptumopa"}"
    SCRIPT_RUNTIME            = "sh"
    SCRIPT_PATH               = "/opt/opa/install/"
  }
}

data "template_file" "api-policy" {
  template = "${file("${path.module}/api-policy.json.tpl")}"

  vars = {
    aws_region     = "${var.aws_region}"
    aws_account_id = "${local.aws_account_id}"
    api_id         = "${var.api_id}"
  }
}

# create api gateway, api methods and associated lambdas
module "api" {
  source                      = "../../modules/api/"
  stage_name                  = "${var.env_prefix}"
  environment_vars            = "${local.environment_vars}"
  api_policy                  = "${data.template_file.api-policy.rendered}"
  data_load_service_role_name = "${var.data_load_service_role_name}"

  vpc_id            = "${local.vpc_id}"
  vpc_cidr_block    = ["${local.vpc_cidr_block}"]
  hybrid_cidr_block = ["${local.hybrid_subnet_cidr_blocks}"]

  # use the new subnet as the private subnet for creating Lambdas
  private_subnet_ids = ["${local.subnet_new_private_subnet_ids}"]
  env_prefix         = "${var.env_prefix}"
  global_tags        = "${var.global_tags}"

  redshift_egress_sg            = "${aws_security_group.redshift_egress_sg.id}"
  opa_api_source_code_s3_bucket = "${module.opa-api.opa_api_source_code_s3_bucket}"
  opa_api_source_code_s3_key    = "${module.opa-api.opa_api_source_code_s3_key}"
  opa_release_sns_role_arn      = "${module.opa-release-setup.opa_release_sns_role_arn}"
  artifacts_s3_id               = "${var.s3_artifacts_id}"
}
