locals {
  is_hybrid            = "${var.is_hybrid == "true"}"
  hybrid_cidr_block    = "10.0.0.0/8"
  hybrid_allowed_ports = [22, 443, 3389, 34952]
}

resource "aws_vpn_gateway" "hybrid_gateway" {
  count  = "${local.is_hybrid ? 1 : 0}"
  vpc_id = "${module.vpc.vpc_id}"
  tags   = "${merge(var.global_tags, map("Name", "main"))}"
}

resource "aws_dx_hosted_private_virtual_interface_accepter" "dx_accepter" {
  count                = "${local.is_hybrid ? 1 : 0}"
  virtual_interface_id = "${var.virtual_interface_id}"
  vpn_gateway_id       = "${aws_vpn_gateway.hybrid_gateway.id}"
  tags                 = "${merge(var.global_tags, map("Side", "Accepter"))}"
}

resource "aws_vpn_gateway_route_propagation" "public_route_gateway_propogation" {
  count          = "${local.is_hybrid ? var.az_count : 0}"
  vpn_gateway_id = "${aws_vpn_gateway.hybrid_gateway.id}"
  route_table_id = "${module.vpc.vpc_public_route_table[count.index]}"
}

resource "aws_vpn_gateway_route_propagation" "private_route_gateway_propogation" {
  count          = "${local.is_hybrid ? var.az_count : 0}"
  vpn_gateway_id = "${aws_vpn_gateway.hybrid_gateway.id}"
  route_table_id = "${module.vpc.vpc_private_route_table[count.index]}"
}

resource "aws_vpn_gateway_route_propagation" "data_route_gateway_propogation" {
  count          = "${local.is_hybrid ? var.az_count : 0}"
  vpn_gateway_id = "${aws_vpn_gateway.hybrid_gateway.id}"
  route_table_id = "${module.data-subnets.subnets_private_route_table[count.index]}"
}

resource "aws_network_acl_rule" "allow_inbound_redshift_port_directconnect" {
  count          = "${local.is_hybrid ? var.dataports_count : 0}"
  network_acl_id = "${module.data-subnets.subnets_private_nacl_id}"
  protocol       = "tcp"
  rule_number    = "${50+count.index}"
  rule_action    = "allow"
  cidr_block     = "${local.hybrid_cidr_block}"
  from_port      = "${var.dataports[count.index]}"
  to_port        = "${var.dataports[count.index]}"
}

resource "aws_network_acl_rule" "allow_inbound_ports_directconnect" {
  count          = "${local.is_hybrid ? length(local.hybrid_allowed_ports) : 0}"
  network_acl_id = "${module.vpc.vpc_private_nacl_id}"
  protocol       = "tcp"
  rule_number    = "${70+count.index}"
  rule_action    = "allow"
  cidr_block     = "${local.hybrid_cidr_block}"
  from_port      = "${local.hybrid_allowed_ports[count.index]}"
  to_port        = "${local.hybrid_allowed_ports[count.index]}"
}

resource "aws_network_acl_rule" "allow_outbound_private_network" {
  count          = "${local.is_hybrid ? 1 : 0}"
  network_acl_id = "${module.data-subnets.subnets_private_nacl_id}"
  protocol       = "tcp"
  rule_number    = 50
  rule_action    = "allow"
  cidr_block     = "${local.hybrid_cidr_block}"
  from_port      = "1024"
  to_port        = "65535"
  egress         = true
}

resource "aws_security_group_rule" "api_gateway_vpce_allow_hybrid_access" {
  count             = "${local.is_hybrid ? 1 : 0}"
  type              = "ingress"
  security_group_id = "${aws_security_group.api_gateway_vpce_sg.id}"
  cidr_blocks       = ["${local.hybrid_cidr_block}"]
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
}
