locals {
  prod_only_count = "${var.is_prod == "true" ? "1" : "0"}"
}

resource "aws_network_acl_rule" "allow_inbound_ssh_from_vpc" {
  count          = "${local.prod_only_count}"
  network_acl_id = "${module.network.vpc_private_nacl_id}"
  protocol       = "tcp"
  egress         = false
  rule_number    = 160
  rule_action    = "allow"
  cidr_block     = "${var.vpc_cidr_block}"
  from_port      = 22
  to_port        = 22
}
