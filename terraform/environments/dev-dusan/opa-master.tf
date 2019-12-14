module "opa-master" {
  source                 = "../../modules/opa-rds"
  vpc_id                 = "vpc-0a44c492a7e854b71"
  data_subnet_ids        = ["subnet-07fc0855336fd60a6", "subnet-0e3cefeddbf5b2a5e"]
  vpc_cidr_block         = ["10.250.166.0/24"]
  hybrid_cidr_block      = ["10.0.0.0/8"]
  env_prefix             = "${var.env_prefix}"
  tag_name_identifier    = "nonprodoptumopa"
  database_identifier    = "${var.env_prefix}-opa-master"
  database_name          = "opa_master"
  master_username        = "opa_admin"
  engine                 = "postgres"
  engine_version         = "10.6"
  parameter_group_family = "postgres10"
  instance_class         = "db.t3.small"
  instance_port          = 5432
  global_tags            = "${local.global_tags}"
}

