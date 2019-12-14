locals {
  vpc_cidr_block = "10.250.0.0/16"
  account_id     = "${data.aws_caller_identity.current_identity.account_id}"

  global_tags = {
    "optum:environment" = "${var.env_prefix}"
    "optum:application" = "OPA"
    "terraform"         = "true"
  }
}

data "aws_caller_identity" "current_identity" {}

module "base-shared" {
  source = "../../modules/base-shared"

  # environment setup
  is_prod                = "true"
  aws_region             = "${var.aws_region}"
  aws_replication_region = "${var.aws_replication_region}"
  aws_profile            = "saml"
  env_prefix             = "${var.env_prefix}"

  # s3
  artifacts_bucket_name_suffix         = "opa-artifacts"
  client_data_bucket_name_suffix       = "opa-client-data"
  registry_data_bucket_name_suffix     = "opa-registry-data"
  tag_name_identifier                  = "prodoptumopa"
  flat_files_bucket_name_suffix        = "opa-flat-files"
  opa_configuration_bucket_name_suffix = "opa-configuration"
  s3_mstr_backups_bucket_name_suffix   = "opa-mstr-backups"

  # network
  is_hybrid_network           = "false"
  network_name                = "prodoptumopa"
  vpc_cidr_block              = "${local.vpc_cidr_block}"
  public_subnets_cidr_blocks  = ["${cidrsubnet(local.vpc_cidr_block, 5, 1)}", "${cidrsubnet(local.vpc_cidr_block, 5, 2)}"]
  private_subnets_cidr_blocks = ["${cidrsubnet(local.vpc_cidr_block, 5, 3)}", "${cidrsubnet(local.vpc_cidr_block, 5, 4)}"]
  data_subnets_cidr_blocks    = ["${cidrsubnet(local.vpc_cidr_block, 5, 5)}", "${cidrsubnet(local.vpc_cidr_block, 5, 6)}"]
  dataports_count             = 3
  dataports                   = ["5439", "5432", "3306"]

  # tagging
  global_tags = "${local.global_tags}"
}
