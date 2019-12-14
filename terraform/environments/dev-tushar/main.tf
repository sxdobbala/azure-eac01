locals {
  global_tags = {
    "${var.tag_prefix}:environment" = "${var.env_prefix}"
    "${var.tag_prefix}:application" = "${var.application_tag}"
    "terraform"                     = "true"
  }

  vpc_id                        = "${data.terraform_remote_state.shared.vpc_id}"
  vpc_cidr_block                = "${data.terraform_remote_state.shared.vpc_cidr_block}"
  vpc_private_subnet_ids        = "${data.terraform_remote_state.shared.vpc_private_subnet_ids}"
  hybrid_subnet_cidr_blocks     = "${data.terraform_remote_state.shared.hybrid_subnet_cidr_blocks}"
  s3_opa_logs_id                = "${data.terraform_remote_state.shared.s3_opa_logs_id}"
  s3_registry_data_id           = "${data.terraform_remote_state.shared.s3_registry_data_id}"
  artifacts_s3_id               = "${data.terraform_remote_state.shared.artifacts_s3_id}"
  ca_public_cert_ssm_param_name = "${data.terraform_remote_state.shared.ca_public_cert_ssm_param_name}"
  ca_private_key_ssm_param_name = "${data.terraform_remote_state.shared.ca_private_key_ssm_param_name}"
}

module "dataloader-eb" {
  source                            = "../../modules/dataloader"
  env_prefix                        = "${var.env_prefix}"
  global_tags                       = "${local.global_tags}"
  vpc_id                            = "${local.vpc_id}"
  private_subnet_ids                = "${local.vpc_private_subnet_ids}"
  vpc_cidr_block                    = "${local.vpc_cidr_block}"
  is_hybrid                         = "true"
  hybrid_subnet_cidr_blocks         = "${local.hybrid_subnet_cidr_blocks}"
  redshift_egress_security_group_id = "sg-010fe842d10b0e642"                   # Will be replaced with ${module.base.redshift_egress_sg_id} once integrated with logical environment
  ec2_instance_type                 = "t2.nano"
  autoscale_min                     = "1"
  autoscale_max                     = "1"
  elb_logs_bucket_id                = "${local.s3_opa_logs_id}"
  ca_private_key_ssm_param_name     = "${local.ca_private_key_ssm_param_name}"
  ca_public_cert_ssm_param_name     = "${local.ca_public_cert_ssm_param_name}"
  s3_bucket_id                      = "${local.s3_registry_data_id}"
}
