module "link-integration" {
  source                        = "../../modules/link-integration"
  env_prefix                    = "${var.env_prefix}"
  s3_bucket                     = "${data.terraform_remote_state.shared.s3_client_data_id}"
  registry_api_url              = "https://dev-dataloader.us-east-1.elasticbeanstalk.com/"
  link_service_role_arn         = "${data.terraform_remote_state.shared.link_service_role_arn}"
  vpc_id                        = "vpc-0a44c492a7e854b71"
  vpc_cidr_block                = ["10.250.166.0/24"]
  hybrid_cidr_block             = ["10.0.0.0/8"]
  private_subnet_ids            = ["subnet-0aa17f69172a96b13", "subnet-01d409d50494e8d12"]
  opa_api_source_code_s3_bucket = "${module.opa-api.opa_api_source_code_s3_bucket}"
  opa_api_source_code_s3_key    = "${module.opa-api.opa_api_source_code_s3_key}"
  global_tags                   = "${local.global_tags}"
  dataloader_egress_sg_id       = "sg-0e098945190094661"
}
