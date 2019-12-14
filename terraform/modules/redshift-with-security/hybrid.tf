locals {
  is_hybrid = "${var.is_hybrid == "true"}"
}

resource "aws_security_group_rule" "redshift-sg-ingress-allow-hybrid-subnets" {
  count             = "${local.is_hybrid ? 1 : 0}"
  type              = "ingress"
  from_port         = "${module.redshift_instance.redshift_cluster_port}"
  to_port           = "${module.redshift_instance.redshift_cluster_port}"
  protocol          = "tcp"
  cidr_blocks       = ["${var.hybrid_subnet_cidr_blocks}"]
  security_group_id = "${module.redshift_instance.redshift_security_group_id}"
}

resource "aws_security_group_rule" "redshift-sg-egress-allow-hybrid-subnets" {
  count             = "${local.is_hybrid ? 1 : 0}"
  type              = "egress"
  from_port         = "${module.redshift_instance.redshift_cluster_port}"
  to_port           = "${module.redshift_instance.redshift_cluster_port}"
  protocol          = "tcp"
  cidr_blocks       = ["${var.hybrid_subnet_cidr_blocks}"]
  security_group_id = "${aws_security_group.redshift-sg-egress.id}"
}
