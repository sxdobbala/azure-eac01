locals {
  global_tags = {
    "optum:environment" = "${var.env_prefix}"
    "optum:application" = "OPA"
    "terraform"         = "true"
  }

  secondary_cidr_block = "10.251.0.0/16"
}

module "base-shared" {
  source = "../../modules/base-shared"

  # environment setup
  is_prod                = "false"
  aws_region             = "${var.aws_region}"
  aws_replication_region = "${var.aws_replication_region}"
  aws_profile            = "saml"
  env_prefix             = "${var.env_prefix}"

  # s3
  artifacts_bucket_name_suffix         = "opa-artifacts"
  client_data_bucket_name_suffix       = "opa-client-data"
  registry_data_bucket_name_suffix     = "opa-registry-data"
  tag_name_identifier                  = "nonprodoptumopa"
  flat_files_bucket_name_suffix        = "opa-flat-files"
  opa_configuration_bucket_name_suffix = "opa-configuration"
  s3_mstr_backups_bucket_name_suffix   = "opa-mstr-backups"

  # network
  is_hybrid_network           = "true"
  network_name                = "nonprodoptumopadevonly"
  vpc_cidr_block              = "10.250.166.0/24"
  vpc_secondary_cidr_blocks   = ["${local.secondary_cidr_block}"]          # Does not get hybrid networking!! 
  public_subnets_cidr_blocks  = ["10.250.166.0/27", "10.250.166.32/27"]
  private_subnets_cidr_blocks = ["10.250.166.64/27", "10.250.166.96/27"]
  data_subnets_cidr_blocks    = ["10.250.166.160/27", "10.250.166.128/27"]

  # New private subnets in secondary CIDR block, does not get hybrid network
  new_private_subnets_cidr_blocks = ["${cidrsubnet(local.secondary_cidr_block, 5, 0)}", "${cidrsubnet(local.secondary_cidr_block, 5, 1)}"]
  dataports_count                 = 3
  dataports                       = ["5439", "5432", "3306"]
  virtual_interface_id            = "dxvif-fgde56ov"

  # tagging
  global_tags = "${local.global_tags}"
}
