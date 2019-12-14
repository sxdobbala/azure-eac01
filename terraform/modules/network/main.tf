module "vpc" {
  source     = "git::https://github.optum.com/oaccoe/aws_vpc.git//terraform_module/vpc?ref=v1.7.10"
  vpc_cidr   = "${var.vpc_cidr_block}"
  aws_region = "${var.aws_region}"
  aws_azs    = ["${var.aws_azs}"]

  private_subnets_cidr = ["${var.private_subnets_cidr_blocks}"]
  public_subnets_cidr  = ["${var.public_subnets_cidr_blocks}"]
  tag_name_identifier  = "${var.network_name}"

  vpc_name                                        = "${var.network_name}"
  internet_gateway_enabled                        = true
  nat_enabled                                     = true
  associate_s3_endpoint_with_public_subnets       = true
  associate_dynamodb_endpoint_with_public_subnets = true
  enable_dynamodb_endpoint                        = true
  enable_s3_endpoint                              = true

  global_tags = "${var.global_tags}"
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  count      = "${length(var.vpc_secondary_cidr_blocks)}"
  vpc_id     = "${module.vpc.vpc_id}"
  cidr_block = "${var.vpc_secondary_cidr_blocks[count.index]}"
}

module "data-subnets" {
  source                                         = "git::https://github.optum.com/oaccoe/aws_vpc.git//terraform_module/subnets?ref=v1.7.10"
  aws_region                                     = "${var.aws_region}"
  vpc_id                                         = "${module.vpc.vpc_id}"
  create_nacl_for_private_subnets                = true
  number_of_private_subnets                      = "${var.az_count}"
  list_of_aws_az                                 = ["${var.aws_azs}"]
  list_of_cidr_block_for_public_subnets          = []
  list_of_cidr_block_for_private_subnets         = ["${var.data_subnets_cidr_blocks}"]
  associate_s3_endpoint_with_private_route_table = true
  vpc_endpoint_s3_id                             = "${module.vpc.vpc_s3_endpoint}"
  tag_name_identifier                            = "${var.network_name}-data"

  global_tags = "${var.global_tags}"
}

module "new-private-subnets" {
  source                                         = "git::https://github.optum.com/oaccoe/aws_vpc.git//terraform_module/subnets?ref=v1.7.10"
  aws_region                                     = "${var.aws_region}"
  vpc_id                                         = "${module.vpc.vpc_id}"
  number_of_private_subnets                      = "${length(var.new_private_subnets_cidr_blocks)}"
  list_of_aws_az                                 = ["${var.aws_azs}"]
  list_of_cidr_block_for_public_subnets          = []
  list_of_cidr_block_for_private_subnets         = ["${var.new_private_subnets_cidr_blocks}"]                                               # should be empty for prod-shared
  associate_s3_endpoint_with_private_route_table = true
  vpc_endpoint_s3_id                             = "${module.vpc.vpc_s3_endpoint}"
  tag_name_identifier                            = "${var.network_name}-new-private"

  # TODO: don't rely on NAT, use VPC endpoints (although that may break MSTR installation)
  associate_nat_gateway_with_private_route_table = true
  vpc_nat_gateway_ids                            = "${module.vpc.vpc_nat_gateway}"

  # prefer SG for granular ingress/egress control
  create_nacl_for_private_subnets = false

  global_tags = "${var.global_tags}"
}

data "aws_caller_identity" "current" {}

resource "aws_network_acl_rule" "allow_inbound_data_ports" {
  network_acl_id = "${module.data-subnets.subnets_private_nacl_id}"
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = "${100+count.index}"
  cidr_block     = "${module.vpc.vpc_cidr_block}"
  from_port      = "${var.dataports[count.index]}"
  to_port        = "${var.dataports[count.index]}"
  count          = "${var.dataports_count}"
}

resource "aws_network_acl_rule" "private_outbound_within_vpc" {
  network_acl_id = "${module.data-subnets.subnets_private_nacl_id}"
  egress         = true
  protocol       = "-1"
  rule_number    = 110
  rule_action    = "allow"
  cidr_block     = "${module.vpc.vpc_cidr_block}"
  from_port      = 0
  to_port        = 0
}

data "aws_vpc_endpoint" "s3" {
  vpc_id = "${module.vpc.vpc_id}"
  id     = "${module.vpc.vpc_s3_endpoint}"
}

resource "aws_network_acl_rule" "allow_s3_443_outbound" {
  network_acl_id = "${module.data-subnets.subnets_private_nacl_id}"
  egress         = true
  protocol       = "tcp"
  rule_number    = "${120+count.index}"
  rule_action    = "allow"
  cidr_block     = "${data.aws_vpc_endpoint.s3.cidr_blocks[count.index]}"
  from_port      = 443
  to_port        = 443
  count          = "${var.az_count}"
}

resource "aws_network_acl_rule" "allow_s3_ephemeral_back" {
  network_acl_id = "${module.data-subnets.subnets_private_nacl_id}"
  egress         = false
  protocol       = "tcp"
  rule_number    = "${130+count.index}"
  rule_action    = "allow"
  cidr_block     = "${data.aws_vpc_endpoint.s3.cidr_blocks[count.index]}"
  from_port      = 1024
  to_port        = 65535
  count          = "${var.az_count}"
}

resource "aws_vpc_endpoint" "api_gateway_endpoint" {
  vpc_id            = "${module.vpc.vpc_id}"
  service_name      = "com.amazonaws.${var.aws_region}.execute-api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.api_gateway_vpce_sg.id}",
  ]

  subnet_ids          = ["${module.vpc.vpc_private_subnet_ids}"]
  private_dns_enabled = true
}

resource "aws_security_group" "api_gateway_vpce_sg" {
  name        = "api-gateway-vpce-sg"
  description = "Security group to allow VPC access to API gateway"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${module.vpc.vpc_cidr_block}"]
  }

  tags = "${var.global_tags}"
}
