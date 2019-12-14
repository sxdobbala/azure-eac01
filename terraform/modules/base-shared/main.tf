locals {
  mstr_ingress_cidr_block = "${var.is_prod == "true" ? "127.0.0.1/32" : module.network.hybrid_subnet_cidr_blocks[0]}"

  # leave the name short for ci - longer names are throwing error "S3 name too long"
  opagoldpipelines_name = "${var.env_prefix == "ci" ? "ci" : "opagold"}"

  aws_azs_by_region = {
    "us-east-1" = ["${var.aws_region}a", "${var.aws_region}b"]
    "us-west-2" = ["${var.aws_region}a", "${var.aws_region}b"]
  }
}

module "network" {
  source                    = "../network"
  is_hybrid                 = "${var.is_hybrid_network}"
  vpc_cidr_block            = "${var.vpc_cidr_block}"
  vpc_secondary_cidr_blocks = ["${var.vpc_secondary_cidr_blocks}"]
  aws_region                = "${var.aws_region}"
  aws_azs                   = ["${local.aws_azs_by_region[var.aws_region]}"]

  az_count     = "2"
  network_name = "${var.network_name}"

  virtual_interface_id            = "dxvif-fgde56ov"
  public_subnets_cidr_blocks      = ["${var.public_subnets_cidr_blocks}"]
  private_subnets_cidr_blocks     = ["${var.private_subnets_cidr_blocks}"]
  data_subnets_cidr_blocks        = ["${var.data_subnets_cidr_blocks}"]
  new_private_subnets_cidr_blocks = ["${var.new_private_subnets_cidr_blocks}"]
  dataports_count                 = "${var.dataports_count}"
  dataports                       = ["${var.dataports}"]

  global_tags = "${var.global_tags}"
}

module "microstrategyonaws-base-updates" {
  source              = "../microstrategyonaws-base-updates"
  ingress_cidr_block  = "${local.mstr_ingress_cidr_block}"
  vpc                 = "${module.network.vpc_id}"
  vpc_cidr_block      = "${module.network.vpc_cidr_block}"
  appstream_sg_id     = "${module.appstream.appstream_sg_id}"
  publicsubnet01      = "${module.network.vpc_public_subnet_ids[0]}"
  publicsubnet02      = "${module.network.vpc_public_subnet_ids[1]}"
  privatesubnet01     = "${module.network.subnet_new_private_subnet_ids[0]}"
  privatesubnet02     = "${module.network.subnet_new_private_subnet_ids[1]}"
  artifacts_s3_bucket = "${module.s3-opa-artifacts.id}"

  global_tags = "${var.global_tags}"
  env_prefix  = "${var.env_prefix}"
  is_prod     = "${var.is_prod}"
}

module "opagoldpipelines" {
  source = "../opagoldpipelines"
  name   = "${local.opagoldpipelines_name}"

  global_tags = "${var.global_tags}"
}

resource "aws_codedeploy_app" "mstrcodedeploy" {
  name = "MSTRCodeDeploy"
}

module "aws-inspector" {
  source                  = "git::https://github.optum.com/oaccoe/aws_inspector.git//terraform_module"
  aws_region              = "${var.aws_region}"
  aws_profile             = "${var.aws_profile}"
  tag_value_for_instances = "${var.tag_value_for_instances}"
  assessment_target_name  = "${var.assessment_target_name}"
  env_prefix              = "${var.env_prefix}"
}

# TODO: Uncomment after upgrading to newer version of AWS provider
# https://github.com/terraform-providers/terraform-provider-aws/issues/8760
# resource "aws_ebs_encryption_by_default" "ebs_encryption" {
#   enabled = true
# }

# Creating a single dataloader elastic beanstalk application per AWS account. 
# Each logical enviroment will then create an elastic beanstalk environment under the same application.
# This simplifies application version management and allows a version to be deployed to multiple eb environments.
resource "aws_elastic_beanstalk_application" "dataloader_eb_app" {
  name        = "dataloader"
  description = "OPA DataLoader API"
}
