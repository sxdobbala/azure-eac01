locals {
  cidr_subnet1 = "${var.is_prod == "true" ? cidrsubnet(var.vpc_cidr_block, 8, 254) : cidrsubnet(var.vpc_cidr_block, 4, 14)}"
  cidr_subnet2 = "${var.is_prod == "true" ? cidrsubnet(var.vpc_cidr_block, 8, 255) : cidrsubnet(var.vpc_cidr_block, 4, 15)}"
}

module "appstream" {
  source          = "../appstream"
  env_prefix      = "${var.env_prefix}"
  vpc_id          = "${module.network.vpc_id}"
  vpc_cidr_blocks = ["${module.network.vpc_cidr_blocks}"]

  image_arn                              = "arn:aws:appstream:${var.aws_region}:760182235631:image/OPABreakGlassImage-4"
  egress_port_numbers                    = ["22", "34952", "5439", "3306", "5432"]
  list_of_aws_azs                        = ["${var.aws_region}a", "${var.aws_region}c"]
  list_of_cidr_block_for_private_subnets = ["${local.cidr_subnet1}", "${local.cidr_subnet2}"]

  global_tags = "${var.global_tags}"
}
