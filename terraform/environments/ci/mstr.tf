locals {
  mstr_id_01 = "d01"
}

# TODO: this should be moved inside the "microstrategyinstance" module
data "aws_ssm_parameter" "mstrapikey" {
  name = "mstrapikey"
}

module "mstropadev1-team" {
  source                    = "../../modules/microstrategyinstance"
  environmentType           = "Team"
  environmentName           = "opadev1-team"
  apikey                    = "${data.aws_ssm_parameter.mstrapikey.value}"
  env_prefix                = "${var.env_prefix}"
  app_elb_path              = "${local.mstr_id_01}"
  opa_release_sns_topic_arn = "${module.base.opa_release_sns_topic_arn}"
  global_tags               = "${local.global_tags}"
  customer                  = "${local.mstr_id_01}"
}
