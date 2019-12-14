#module "opa-app-elb" {
#  source                = "../../modules/opa-app-elb"
#  env_prefix            = "${var.env_prefix}"
#  vpc_id                = "vpc-0a44c492a7e854b71"
#  vpc_public_subnet_ids = ["subnet-0f73994e63cf66857", "subnet-0ad117f246860dd50"]
#  s3_opa_logs_id        = "${data.terraform_remote_state.shared.s3_opa_logs_id}"
#  ssl_cert_name         = "devcloud"
#  global_tags           = "${local.global_tags}"
#}