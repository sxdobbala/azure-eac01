module "mstr-postinstall" {
  source                        = "../mstr-postinstall"
  env_prefix                    = "${var.env_prefix}"
  artifacts_s3_bucket           = "${local.s3_artifacts_id}"
  aws_region                    = "${var.aws_region}"
  opa_api_source_code_s3_bucket = "${module.opa-api.opa_api_source_code_s3_bucket}"
  opa_api_source_code_s3_key    = "${module.opa-api.opa_api_source_code_s3_key}"
  dataloader_egress_sg_id       = "${module.dataloader.dataloader_egress_sg_id}"
  global_tags                   = "${var.global_tags}"
}
