data "aws_security_group" "platform_instance_sg" {
  filter = [
    {
      name   = "vpc-id"
      values = ["${var.vpc_id}"]
    },
    {
      name   = "group-name"
      values = ["${var.env_id}-PlatformInstanceSG-*"]
    },
  ]
}

data "aws_security_group" "app_elb_sg" {
  filter = [
    {
      name   = "vpc-id"
      values = ["${var.vpc_id}"]
    },
    {
      name   = "group-name"
      values = ["MicroStrategyOnAWS-AppELBSG-*"]
    },
  ]
}

resource "aws_security_group_rule" "allow_inbound_to_ec2" {
  type                     = "ingress"
  security_group_id        = "${data.aws_security_group.platform_instance_sg.id}"
  source_security_group_id = "${data.aws_security_group.app_elb_sg.id}"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  description              = "Allow inbound to MSTR EC2 from ELB"
}

resource "aws_security_group_rule" "allow_outbound_from_elb" {
  type                     = "egress"
  security_group_id        = "${data.aws_security_group.app_elb_sg.id}"
  source_security_group_id = "${data.aws_security_group.platform_instance_sg.id}"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  description              = "Allow outbound from ELB to MSTR EC2"
}

data "aws_lb" "app_elb" {
  name = "${var.env_prefix}-appelb"
}

data "aws_lb_listener" "app_elb_listener_port_443" {
  load_balancer_arn = "${data.aws_lb.app_elb.arn}"
  port              = 443
}

data "aws_lb_target_group" "platform_target_group" {
  name = "${var.env_id}-App-8443"
}

resource "aws_lb_listener_rule" "app_elb_listener_rule" {
  count        = "${var.create_listener_rule == "true" ? 1 : 0}"
  listener_arn = "${data.aws_lb_listener.app_elb_listener_port_443.arn}"

  action {
    type             = "forward"
    target_group_arn = "${data.aws_lb_target_group.platform_target_group.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/${var.app_elb_path}/*"]
  }
}
