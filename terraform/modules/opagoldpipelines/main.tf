data "aws_region" "current" {}

locals {
  source-amis-goldpipeline1-mstr101101 = {
    "us-east-1" = "ami-c1003ebe"
    "us-west-2" = "ami-07e2cb57b7374fb4a"
  }

  source-amis-goldpipeline1-mstr2019-110101 = {
    "us-east-1" = "ami-09f09576c1a51ea38"
    "us-west-2" = "ami-0ab22f4ea5e6a30c4"
  }

  source-amis-goldpipeline1-mstr2020-110200 = {
    "us-east-1" = "ami-036c09388579ba8e3"
    "us-west-2" = "ami-06f2db11ecdd02071"
  }

  aws_region = "${data.aws_region.current.name}"
}

module "goldpipelinevpc" {
  source                                    = "git::https://github.optum.com/oaccoe/aws_vpc.git//terraform_module/vpc?ref=v1.7.10"
  vpc_cidr                                  = "10.0.0.0/16"
  aws_region                                = "${local.aws_region}"
  aws_azs                                   = ["${local.aws_region}a"]
  tag_name_identifier                       = "goldpipeline-${var.name}"
  vpc_name                                  = "goldpipeline-${var.name}"
  internet_gateway_enabled                  = true
  nat_enabled                               = true
  associate_s3_endpoint_with_public_subnets = true
  enable_s3_endpoint                        = true
  global_tags                               = "${var.global_tags}"
}

module "goldpipeline1-mstr101101" {
  source        = "git::https://github.optum.com/oaccoe/aws_goldpipeline.git?ref=v1.1.4"
  name          = "mstr101101-${var.name}"
  vpc_id        = "${module.goldpipelinevpc.vpc_id}"
  subnet_ids    = "${module.goldpipelinevpc.vpc_private_subnet_ids}"
  ami_name      = "MSTR_101101"
  source_ami    = "${local.source-amis-goldpipeline1-mstr101101[local.aws_region]}"
  instance_type = "r4.large"
}

module "goldpipeline1-mstr2019-110101" {
  source        = "git::https://github.optum.com/oaccoe/aws_goldpipeline.git?ref=v1.1.4"
  name          = "mstr110101-${var.name}"
  vpc_id        = "${module.goldpipelinevpc.vpc_id}"
  subnet_ids    = "${module.goldpipelinevpc.vpc_private_subnet_ids}"
  ami_name      = "MSTR_2019"
  source_ami    = "${local.source-amis-goldpipeline1-mstr2019-110101[local.aws_region]}"
  instance_type = "r4.large"
}

module "goldpipeline1-mstr2020-110200" {
  # use OPA fork that keeps X11 so we don't break MSTR installer
  source        = "git::https://github.optum.com/opa/aws_goldpipeline.git"
  name          = "mstr110200-${var.name}"
  vpc_id        = "${module.goldpipelinevpc.vpc_id}"
  subnet_ids    = "${module.goldpipelinevpc.vpc_private_subnet_ids}"
  ami_name      = "MSTR_2020"
  source_ami    = "${local.source-amis-goldpipeline1-mstr2020-110200[local.aws_region]}"
  instance_type = "r4.large"
}
