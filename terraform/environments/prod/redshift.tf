# BCBS
module "opa-redshift-1" {
  source                      = "../../modules/redshift-with-security"
  label                       = "opa-prod-redshift-1"
  vpc_id                      = "${local.vpc_id}"
  subnet_ids                  = ["${local.subnet_data_subnet_ids}"]
  subnet_cidr_blocks          = ["${local.subnet_data_subnet_cidr_blocks}"]
  database_name               = "prod"
  aws_az                      = ""
  number_of_nodes             = "4"
  master_username             = "opa_admin"
  cluster_type                = "multi-node"
  snapshot_identifier         = ""                                            # TODO: make this optional in redshift-with-security module; underlying EAC defaults to empty
  enhanced_vpc_routing        = "true"
  vpc_s3_endpoint_cidr_blocks = ["${local.vpc_s3_endpoint_cidr_blocks}"]
  instance_type               = "ds2.xlarge"
  appstream_sg_id             = "${local.appstream_sg_id}"
  redshift_egress_sg_id       = "${module.base.redshift_egress_sg_id}"
  redshift_iam_roles_arn      = ["${local.redshift_service_access_role_arn}"]
  global_tags                 = "${local.global_tags}"
}

# Ascension
module "opa-redshift-2" {
  source                      = "../../modules/redshift-with-security"
  label                       = "opa-prod-redshift-2"
  vpc_id                      = "${local.vpc_id}"
  subnet_ids                  = ["${local.subnet_data_subnet_ids}"]
  subnet_cidr_blocks          = ["${local.subnet_data_subnet_cidr_blocks}"]
  database_name               = "prod"
  aws_az                      = ""
  number_of_nodes             = "4"
  master_username             = "opa_admin"
  cluster_type                = "multi-node"
  snapshot_identifier         = ""                                            # TODO: make this optional in redshift-with-security module; underlying EAC defaults to empty
  enhanced_vpc_routing        = "true"
  vpc_s3_endpoint_cidr_blocks = ["${local.vpc_s3_endpoint_cidr_blocks}"]
  instance_type               = "ds2.xlarge"
  appstream_sg_id             = "${local.appstream_sg_id}"
  redshift_egress_sg_id       = "${module.base.redshift_egress_sg_id}"
  redshift_iam_roles_arn      = ["${local.redshift_service_access_role_arn}"]
  global_tags                 = "${local.global_tags}"
}

# Multi-tenant
module "opa-redshift-3" {
  source                      = "../../modules/redshift-with-security"
  label                       = "opa-prod-redshift-3"
  vpc_id                      = "${local.vpc_id}"
  subnet_ids                  = ["${local.subnet_data_subnet_ids}"]
  subnet_cidr_blocks          = ["${local.subnet_data_subnet_cidr_blocks}"]
  database_name               = "prod"
  aws_az                      = ""
  number_of_nodes             = "4"
  master_username             = "opa_admin"
  cluster_type                = "multi-node"
  snapshot_identifier         = ""                                            # TODO: make this optional in redshift-with-security module; underlying EAC defaults to empty
  enhanced_vpc_routing        = "true"
  vpc_s3_endpoint_cidr_blocks = ["${local.vpc_s3_endpoint_cidr_blocks}"]
  instance_type               = "ds2.xlarge"
  appstream_sg_id             = "${local.appstream_sg_id}"
  redshift_egress_sg_id       = "${module.base.redshift_egress_sg_id}"
  redshift_iam_roles_arn      = ["${local.redshift_service_access_role_arn}"]
  global_tags                 = "${local.global_tags}"
}

# Mercy

module "opa-redshift-4" {
  source                      = "../../modules/redshift-with-security"
  label                       = "opa-prod-redshift-4"
  vpc_id                      = "${local.vpc_id}"
  subnet_ids                  = ["${local.subnet_data_subnet_ids}"]
  subnet_cidr_blocks          = ["${local.subnet_data_subnet_cidr_blocks}"]
  database_name               = "prod"
  aws_az                      = ""
  number_of_nodes             = "4"
  master_username             = "opa_admin"
  cluster_type                = "multi-node"
  snapshot_identifier         = ""                                                                                                                                                                                                                                                                                                                        # TODO: make this optional in redshift-with-security module; underlying EAC defaults to empty
  enhanced_vpc_routing        = "true"
  vpc_s3_endpoint_cidr_blocks = ["${local.vpc_s3_endpoint_cidr_blocks}"]
  instance_type               = "ds2.xlarge"
  appstream_sg_id             = "${local.appstream_sg_id}"
  wlm_json_configuration      = "[{\"query_concurrency\":10,\"query_group\":[\"MSTR*\"],\"query_group_wild_card\":1,\"user_group\":[],\"user_group_wild_card\":0, \"concurrency_scaling\": \"auto\"},{\"query_concurrency\":3,\"query_group\":[],\"query_group_wild_card\":0,\"user_group\":[],\"user_group_wild_card\":0},{\"short_query_queue\":true}]"
  redshift_egress_sg_id       = "${module.base.redshift_egress_sg_id}"
  redshift_iam_roles_arn      = ["${local.redshift_service_access_role_arn}"]
  global_tags                 = "${local.global_tags}"
}

# BCBS Test
module "opa-redshift-5" {
  source                      = "../../modules/redshift-with-security"
  label                       = "opa-prod-redshift-5"
  vpc_id                      = "${local.vpc_id}"
  subnet_ids                  = ["${local.subnet_data_subnet_ids}"]
  subnet_cidr_blocks          = ["${local.subnet_data_subnet_cidr_blocks}"]
  database_name               = "prod"
  aws_az                      = ""
  number_of_nodes             = "4"
  master_username             = "opa_admin"
  cluster_type                = "multi-node"
  snapshot_identifier         = ""                                            # TODO: make this optional in redshift-with-security module; underlying EAC defaults to empty
  enhanced_vpc_routing        = "true"
  vpc_s3_endpoint_cidr_blocks = ["${local.vpc_s3_endpoint_cidr_blocks}"]
  instance_type               = "dc2.large"
  appstream_sg_id             = "${local.appstream_sg_id}"
  redshift_egress_sg_id       = "${module.base.redshift_egress_sg_id}"
  redshift_iam_roles_arn      = ["${local.redshift_service_access_role_arn}"]
  global_tags                 = "${local.global_tags}"
}
