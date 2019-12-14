module "opa-app-elb" {
  source                = "../../modules/opa-app-elb"
  env_prefix            = "${var.env_prefix}"
  vpc_id                = "${local.vpc_id}"
  vpc_public_subnet_ids = "${local.vpc_public_subnet_ids}"
  s3_opa_logs_id        = "${local.s3_opa_logs_id}"
  ssl_cert_name         = "devcloud"
  global_tags           = "${local.global_tags}"
}
