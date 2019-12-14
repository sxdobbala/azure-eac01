# TODO: this should be moved inside the "microstrategyinstance" module
data "aws_ssm_parameter" "mstrapikey" {
  name = "mstrapikey"
}

module "opa-mstr-1" {
  source                    = "../../modules/microstrategyinstance"
  environmentType           = "Enterprise"
  environmentName           = "opa-prod-mstr-enterprise-1"
  apikey                    = "${data.aws_ssm_parameter.mstrapikey.value}"
  env_prefix                = "${var.env_prefix}"
  platformInstanceType      = "r4.2xlarge"
  app_elb_path              = "p01"
  opa_release_sns_topic_arn = "${module.base.opa_release_sns_topic_arn}"
  global_tags               = "${local.global_tags}"
  customer                  = "BCBS"
}

module "opa-mstr-2" {
  source                    = "../../modules/microstrategyinstance"
  environmentType           = "Enterprise"
  environmentName           = "opa-prod-mstr-enterprise-2"
  apikey                    = "${data.aws_ssm_parameter.mstrapikey.value}"
  env_prefix                = "${var.env_prefix}"
  platformInstanceType      = "r4.4xlarge"
  app_elb_path              = "p02"
  opa_release_sns_topic_arn = "${module.base.opa_release_sns_topic_arn}"
  global_tags               = "${local.global_tags}"
  customer                  = "Ascension"
}

module "opa-mstr-3" {
  source                    = "../../modules/microstrategyinstance"
  environmentType           = "Enterprise"
  environmentName           = "opa-prod-mstr-enterprise-3"
  apikey                    = "${data.aws_ssm_parameter.mstrapikey.value}"
  env_prefix                = "${var.env_prefix}"
  platformInstanceType      = "r4.large"
  app_elb_path              = "p03"
  opa_release_sns_topic_arn = "${module.base.opa_release_sns_topic_arn}"
  global_tags               = "${local.global_tags}"
  customer                  = "Lahey"
  mstrbak                   = "https://029620356096-opa-artifacts.s3.amazonaws.com/env-160989laio1use18.5/env-160989laio1use1-2019-09-11-10_47_14.367291.tar.gz"
}

module "opa-mstr-4" {
  source                    = "../../modules/microstrategyinstance"
  environmentType           = "Enterprise"
  environmentName           = "opa-prod-mstr-enterprise-4"
  apikey                    = "${data.aws_ssm_parameter.mstrapikey.value}"
  env_prefix                = "${var.env_prefix}"
  platformInstanceType      = "r4.2xlarge"
  app_elb_path              = "p04"
  opa_release_sns_topic_arn = "${module.base.opa_release_sns_topic_arn}"
  global_tags               = "${local.global_tags}"
  customer                  = "OhioHealth"
  mstrbak                   = "https://029620356096-opa-artifacts.s3.amazonaws.com/env-161845laio1use1-2019-09-24-13_12_50.792291.tar.gz"
}

module "opa-mstr-5" {
  source                    = "../../modules/microstrategyinstance"
  environmentType           = "Enterprise"
  environmentName           = "opa-prod-mstr-enterprise-5"
  apikey                    = "${data.aws_ssm_parameter.mstrapikey.value}"
  env_prefix                = "${var.env_prefix}"
  platformInstanceType      = "r4.2xlarge"
  app_elb_path              = "p05"
  opa_release_sns_topic_arn = "${module.base.opa_release_sns_topic_arn}"
  global_tags               = "${local.global_tags}"
  customer                  = "BayCare"
  mstrbak                   = "https://029620356096-opa-artifacts.s3.amazonaws.com/env-161845laio1use1-2019-09-24-13_12_50.792291.tar.gz"
}
