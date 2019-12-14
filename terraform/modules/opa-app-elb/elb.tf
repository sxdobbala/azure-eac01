locals {
  aws_account_id = "${data.aws_caller_identity.current.account_id}"
}

data "aws_caller_identity" "current" {}

data "aws_security_group" "MicroStrategyOnAWS-AppELBSG" {
  filter {
    name   = "vpc-id"
    values = ["${var.vpc_id}"]
  }

  filter {
    name   = "group-name"
    values = ["MicroStrategyOnAWS-AppELBSG-*"]
  }
}

resource "aws_lb" "appelb" {
  name               = "${var.env_prefix}-appelb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${data.aws_security_group.MicroStrategyOnAWS-AppELBSG.id}"]
  subnets            = ["${var.vpc_public_subnet_ids}"]

  enable_deletion_protection = true
  idle_timeout               = 3600

  access_logs {
    bucket  = "${var.s3_opa_logs_id}"
    prefix  = "${var.env_prefix}"
    enabled = true
  }

  tags = "${var.global_tags}"
}

resource "aws_lb_listener" "appelb_https_listener" {
  load_balancer_arn = "${aws_lb.appelb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = "arn:aws:iam::${local.aws_account_id}:server-certificate/${var.ssl_cert_name}"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Bad Request"
      status_code  = "400"
    }
  }
}
