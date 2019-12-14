module "redshift" {
  source                      = "../../modules/redshift-with-security"
  is_hybrid                   = "true"
  label                       = "redshift-ci"
  vpc_id                      = "${local.vpc_id}"
  subnet_ids                  = ["${local.subnet_data_subnet_ids}"]
  subnet_cidr_blocks          = ["${local.subnet_data_subnet_cidr_blocks}"]
  database_name               = "dev"
  aws_az                      = ""
  number_of_nodes             = "1"
  master_username             = "test"
  cluster_type                = "single-node"
  snapshot_identifier         = "final-snapshot-redshift-ci-15635694196172303136"
  enhanced_vpc_routing        = "true"
  hybrid_subnet_cidr_blocks   = ["${local.hybrid_subnet_cidr_blocks}"]
  vpc_s3_endpoint_cidr_blocks = ["${local.vpc_s3_endpoint_cidr_blocks}"]
  instance_type               = "dc2.large"
  wlm_json_configuration      = "[{\"query_concurrency\":10,\"query_group\":[\"MSTR*\"],\"query_group_wild_card\":1,\"user_group\":[],\"user_group_wild_card\":0, \"concurrency_scaling\":\"auto\"},{\"query_concurrency\":3,\"query_group\":[],\"query_group_wild_card\":0,\"user_group\":[],\"user_group_wild_card\":0},{\"short_query_queue\":true}]"
  appstream_sg_id             = "${local.appstream_sg_id}"
  redshift_iam_roles_arn      = ["${local.redshift_service_access_role_arn}"]
  global_tags                 = "${local.global_tags}"
}
