module "opastageredshift1" {
  source                      = "../../modules/redshift-with-security"
  label                       = "opastageredshift-1"
  vpc_id                      = "${local.vpc_id}"
  subnet_ids                  = ["${local.subnet_data_subnet_ids}"]
  subnet_cidr_blocks          = ["${local.subnet_data_subnet_cidr_blocks}"]
  database_name               = "dev"
  aws_az                      = ""
  number_of_nodes             = "4"
  master_username             = "test"
  cluster_type                = "multi-node"
  snapshot_identifier         = ""
  enhanced_vpc_routing        = "true"
  vpc_s3_endpoint_cidr_blocks = ["${local.vpc_s3_endpoint_cidr_blocks}"]
  instance_type               = "ds2.xlarge"
  appstream_sg_id             = "${local.appstream_sg_id}"
  redshift_egress_sg_id       = "${module.base.redshift_egress_sg_id}"
  redshift_iam_roles_arn      = ["${local.redshift_service_access_role_arn}"]
  global_tags                 = "${local.global_tags}"
}
