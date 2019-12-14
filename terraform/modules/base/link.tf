module "link-integration" {
  source                        = "../link-integration"
  env_prefix                    = "${var.env_prefix}"
  s3_bucket                     = "${var.s3_registry_data_id}"
  registry_api_url              = "https://${module.dataloader.cname}"
  link_service_role_arn         = "${var.link_service_role_arn}"
  vpc_id                        = "${local.vpc_id}"
  vpc_cidr_block                = ["${local.vpc_cidr_block}"]
  hybrid_cidr_block             = ["${local.hybrid_subnet_cidr_blocks}"]
  private_subnet_ids            = ["${local.vpc_private_subnet_ids}"]
  opa_api_source_code_s3_bucket = "${module.opa-api.opa_api_source_code_s3_bucket}"
  opa_api_source_code_s3_key    = "${module.opa-api.opa_api_source_code_s3_key}"
  global_tags                   = "${var.global_tags}"
  dataloader_egress_sg_id       = "${module.dataloader.dataloader_egress_sg_id}"
}
