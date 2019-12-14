locals {
  mstr_id_01 = "s01"
  mstr_id_02 = "s02"
}

# TODO: this should be moved inside the "microstrategyinstance" module
data "aws_ssm_parameter" "mstrapikey" {
  name = "mstrapikey"
}

# BCBS
module "mstropastage-enterprise" {
  source                    = "../../modules/microstrategyinstance"
  environmentType           = "Enterprise"
  environmentName           = "opastage-enterprise"
  apikey                    = "${data.aws_ssm_parameter.mstrapikey.value}"
  env_prefix                = "${var.env_prefix}"
  platformInstanceType      = "r4.2xlarge"
  app_elb_path              = "${local.mstr_id_01}"
  opa_release_sns_topic_arn = "${module.base.opa_release_sns_topic_arn}"
  global_tags               = "${local.global_tags}"
  customer                  = "${local.mstr_id_01}"
}

# Ascension
module "opa-mstr-02" {
  source                    = "../../modules/microstrategyinstance"
  environmentType           = "Enterprise"
  environmentName           = "opa-stage-mstr-enterprise-02"
  apikey                    = "${data.aws_ssm_parameter.mstrapikey.value}"
  env_prefix                = "${var.env_prefix}"
  platformInstanceType      = "r4.4xlarge"
  app_elb_path              = "${local.mstr_id_02}"
  opa_release_sns_topic_arn = "${module.base.opa_release_sns_topic_arn}"
  global_tags               = "${local.global_tags}"
  customer                  = "${local.mstr_id_02}"
}
