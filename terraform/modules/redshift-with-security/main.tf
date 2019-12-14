locals {
  cluster-arn-prefix = "arn:aws:redshift:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "redshift_instance" {
  source              = "git::https://github.optum.com/oaccoe/aws_redshift.git?ref=v1.0.2"
  tag_name_identifier = "${var.label}"
  database_identifier = "${var.label}"
  database_name       = "${var.database_name}"
  master_username     = "${var.master_username}"
  master_password     = "${random_string.master-password.result}"
  cluster_type        = "${var.cluster_type}"
  aws_az              = "${var.aws_az}"
  vpc_id              = "${var.vpc_id}"
  subnet_ids          = ["${var.subnet_ids}"]

  source_inbound_sg_list = [
    "${aws_security_group.redshift-sg-egress.id}",
    "${var.appstream_sg_id}",
    "${var.redshift_egress_sg_id}",
  ]

  source_inbound_sg_count   = "3"
  number_of_nodes           = "${var.number_of_nodes}"
  final_snapshot_identifier = "${var.final_snapshot_identifier}"
  snapshot_identifier       = "${var.snapshot_identifier}"
  enhanced_vpc_routing      = "${var.enhanced_vpc_routing}"
  iam_roles_arn             = ["${var.redshift_iam_roles_arn}"]
  instance_type             = "${var.instance_type}"
  wlm_json_configuration    = "${var.wlm_json_configuration}"
  global_tags               = "${var.global_tags}"
}

# Password rules at: https://docs.amazonaws.com/en_us/redshift/latest/APIReference/API_CreateCluster.html
resource "random_string" "master-password" {
  length      = 16
  special     = false
  upper       = true
  lower       = true
  number      = true
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}

resource "aws_security_group_rule" "redshift-allow-https-to-s3" {
  type              = "egress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  cidr_blocks       = ["${var.vpc_s3_endpoint_cidr_blocks}"]
  security_group_id = "${module.redshift_instance.redshift_security_group_id}"
}

resource "aws_security_group" "redshift-sg-egress" {
  description = "Allow DB Port to MSTR"
  vpc_id      = "${var.vpc_id}"
  name        = "${var.label}-redshift-egress"
  tags        = "${merge(var.global_tags, map("Name", "${var.label}-redshift-egress"))}"
}

resource "aws_security_group_rule" "redshift-sg-egress-allow-to-db-port" {
  type              = "egress"
  from_port         = "${module.redshift_instance.redshift_cluster_port}"
  to_port           = "${module.redshift_instance.redshift_cluster_port}"
  protocol          = "tcp"
  cidr_blocks       = ["${var.subnet_cidr_blocks}"]
  security_group_id = "${aws_security_group.redshift-sg-egress.id}"
}

resource "aws_ssm_parameter" "mstr-redshift-sg-param" {
  name      = "redshift.${module.redshift_instance.redshift_cluster_identifier}.sg"
  type      = "SecureString"
  value     = "${aws_security_group.redshift-sg-egress.id}"
  overwrite = true
  tags      = "${var.global_tags}"
}

resource "aws_ssm_parameter" "mstr-redshift-user-param" {
  name      = "redshift.${module.redshift_instance.redshift_cluster_identifier}.username"
  type      = "SecureString"
  value     = "${var.master_username}"
  overwrite = true
  tags      = "${var.global_tags}"
}

resource "aws_ssm_parameter" "mstr-redshift-dns-param" {
  name      = "redshift.${module.redshift_instance.redshift_cluster_identifier}.dns"
  type      = "SecureString"
  value     = "${module.redshift_instance.redshift_cluster_dns_name}"
  overwrite = true
  tags      = "${var.global_tags}"
}

resource "aws_ssm_parameter" "mstr-redshift-db-param" {
  name      = "redshift.${module.redshift_instance.redshift_cluster_identifier}.db"
  type      = "SecureString"
  value     = "${module.redshift_instance.redshift_database_name}"
  overwrite = true
  tags      = "${var.global_tags}"
}

resource "aws_ssm_parameter" "mstr-redshift-endpoint-param" {
  name      = "redshift.${module.redshift_instance.redshift_cluster_identifier}.endpoint"
  type      = "SecureString"
  value     = "${module.redshift_instance.redshift_cluster_dns_endpoint}"
  overwrite = true
  tags      = "${var.global_tags}"
}

// Creating Custom IAM Policy for Redshift Access instead of using the default policy ("RedshiftAccessCluster_{identifier}") created by OACCOE aws_redshift module.
// OACCOE Module doesn't seem to accept custom list of policies. If it changes in future, we can remove the below module.
module "iam_policy" {
  source = "git::https://github.optum.com/CommercialCloud-EAC/aws_iam.git//terraform_module//policy?ref=v1.0.4"

  policy_name        = "${module.redshift_instance.redshift_cluster_identifier}-AccessPolicy"
  policy_description = "Policy to allow IAM access to Redshift cluster ${module.redshift_instance.redshift_cluster_identifier}"
  policy_document    = "${data.aws_iam_policy_document.allow_redshift_access.json}"
}

data "aws_iam_policy_document" "allow_redshift_access" {
  statement = {
    sid       = "AllowDescribeCluster"
    actions   = ["redshift:DescribeClusters"]
    resources = ["${local.cluster-arn-prefix}:cluster:${module.redshift_instance.redshift_cluster_identifier}"]
  }

  statement = {
    sid     = "AllowClusterCredentials"
    actions = ["redshift:GetClusterCredentials"]

    resources = [
      "${local.cluster-arn-prefix}:dbuser:${module.redshift_instance.redshift_cluster_identifier}/${var.master_username}",
      "${local.cluster-arn-prefix}:dbuser:${module.redshift_instance.redshift_cluster_identifier}/h*_user",
      "${local.cluster-arn-prefix}:dbname:${module.redshift_instance.redshift_cluster_identifier}/h*",
    ]
  }
}
