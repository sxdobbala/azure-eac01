locals {
  tag_name_identifier = "${var.is_prod == "true" ? "prodoptumopa" : "nonprodoptumopa"}"
  instance_class      = "${var.is_prod == "true" ? "db.m5.large" : "db.t3.small"}"
}

module "opa-master" {
  source                    = "../../modules/opa-rds"
  vpc_id                    = "${local.vpc_id}"
  data_subnet_ids           = ["${local.subnet_data_subnet_ids}"]
  vpc_cidr_block            = ["${local.vpc_cidr_block}"]
  hybrid_cidr_block         = ["${local.hybrid_subnet_cidr_blocks}"]
  env_prefix                = "${var.env_prefix}"
  tag_name_identifier       = "${local.tag_name_identifier}"
  database_identifier       = "${var.env_prefix}-opa-master"
  database_name             = "opa_master"
  master_username           = "opa_admin"
  engine                    = "postgres"
  engine_version            = "10.6"
  parameter_group_family    = "postgres10"
  instance_class            = "${local.instance_class}"
  instance_port             = 5432
  multi_az                  = "${var.is_prod == "true" ? true : false}"
  apply_changes_immediately = true
  global_tags               = "${var.global_tags}"
}
