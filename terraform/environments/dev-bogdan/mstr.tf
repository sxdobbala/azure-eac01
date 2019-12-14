# resource provisioner for MSTR instances
module "opa-mstr-aws" {
  source          = "../../modules/opa-mstr-aws"
  env_prefix      = "${var.env_prefix}"
  s3_artifacts_id = "${local.artifacts_s3_id}"

  #global_tags = "${var.global_tags}"
}
