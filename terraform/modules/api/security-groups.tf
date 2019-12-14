resource "aws_security_group" "default" {
  name        = "${var.env_prefix}-${var.api_name}-sg"
  description = "Security group for API ${var.api_name}"
  vpc_id      = "${var.vpc_id}"

  # add back the outbound rule that terraform deletes
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr_block}", "${var.hybrid_cidr_block}"]
  }

  tags = "${var.global_tags}"
}
