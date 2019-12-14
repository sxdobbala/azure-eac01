locals {
  identifier = "${var.database_identifier}-rds"

  # only support postgres and mysql with this module for now
  parameter_group_name = "${var.database_identifier}-db-params"
  master_password      = "${random_string.master_password.result}"
}

resource "aws_db_instance" "default" {
  identifier             = "${local.identifier}"
  allocated_storage      = "${var.allocated_storage}"
  engine                 = "${var.engine}"
  engine_version         = "${var.engine_version}"
  instance_class         = "${var.instance_class}"
  port                   = "${var.instance_port}"
  publicly_accessible    = "false"
  name                   = "${var.database_name}"
  username               = "${var.master_username}"
  password               = "${local.master_password}"
  parameter_group_name   = "${local.parameter_group_name}"
  db_subnet_group_name   = "${aws_db_subnet_group.default.name}"
  multi_az               = "${var.multi_az}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  storage_encrypted      = "true"
  kms_key_id             = "${var.kms_key_id_arn}"

  monitoring_interval        = "${var.monitoring_interval}"
  monitoring_role_arn        = "${var.monitoring_interval != 0 ? module.create-role-for-enhanced-monitoring.role_arn : ""}"
  auto_minor_version_upgrade = "${var.auto_minor_version_upgrade}"

  iam_database_authentication_enabled = "${var.iam_auth_enabled}"
  apply_immediately                   = "${var.apply_changes_immediately}"
  backup_retention_period             = "${var.backup_retention_period}"
  backup_window                       = "${var.backup_window}"
  maintenance_window                  = "${var.maintenance_window}"
  skip_final_snapshot                 = "${var.skip_final_snapshot}"
  final_snapshot_identifier           = "final-snapshot-${var.database_identifier}-${substr(uuid(), 0, 8)}"
  tags                                = "${merge(map("Name", "${var.tag_name_identifier}-${var.database_identifier}-rds-instance-n"),var.global_tags)}"

  lifecycle = {
    ignore_changes = ["final_snapshot_identifier"]
  }
}

resource "aws_ssm_parameter" "master-password" {
  name      = "/${var.env_prefix}/${var.database_identifier}.master-password"
  type      = "SecureString"
  value     = "${local.master_password}"
  overwrite = true
  tags      = "${var.global_tags}"
}

resource "aws_db_parameter_group" "postgres_param_group" {
  count       = "${var.engine == "postgres" ? 1 : 0}"
  name        = "${local.parameter_group_name}"
  family      = "postgres10"
  description = "Parameter group for ${local.identifier}"

  parameter {
    name  = "ssl"
    value = "1"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = "${merge(map("rds_instance_identifier", "${var.database_identifier}"),var.global_tags)}"
}

resource "aws_db_parameter_group" "mysql_param_group" {
  count       = "${var.engine == "mysql" ? 1 : 0}"
  name        = "${local.parameter_group_name}"
  family      = "${var.parameter_group_family}"
  description = "Parameter group for ${local.identifier}"

  tags = "${merge(map("rds_instance_identifier", "${var.database_identifier}"),var.global_tags)}"
}

resource "aws_security_group" "default" {
  name        = "${var.database_identifier}-sg"
  description = "Security group for ${local.identifier}"
  vpc_id      = "${var.vpc_id}"
  tags        = "${merge(map("Name", "${var.tag_name_identifier}-${var.database_identifier}-sg"),var.global_tags)}"

  ingress {
    from_port   = "${var.instance_port}"
    to_port     = "${var.instance_port}"
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr_block}", "${var.hybrid_cidr_block}"]
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.database_identifier}-database-subnet-group"
  subnet_ids = ["${var.data_subnet_ids}"]
  tags       = "${merge(map("Name", "${var.tag_name_identifier}-${var.database_identifier}-database-subnet-group"),var.global_tags)}"
}

resource "aws_db_event_subscription" "instance" {
  count            = "${var.event_subscription_cluster_config["enable"]}"
  name             = "${var.event_subscription_cluster_config["name-prefix"]}-${var.database_identifier}"
  sns_topic        = "${var.event_subscription_cluster_config["sns_topic_arn"]}"
  source_type      = "db-instance"
  source_ids       = ["${aws_db_instance.default.id}"]
  event_categories = ["${split(",",var.event_subscription_cluster_config["event_categories"])}"]
  tags             = "${merge(map("Name", "${var.tag_name_identifier}-${var.database_identifier}-db-instance-event-subscription"),var.global_tags)}"
}

# Create parametergroup (db parameter group only ) event notification 
resource "aws_db_event_subscription" "parametergroup" {
  count            = "${var.event_subscription_parametergroup_config["enable"]}"
  name             = "${var.event_subscription_parametergroup_config["name-prefix"]}-${var.database_identifier}"
  sns_topic        = "${var.event_subscription_parametergroup_config["sns_topic_arn"]}"
  source_type      = "db-parameter-group"
  source_ids       = ["${local.db_parameter_group}"]
  event_categories = ["${split(",",var.event_subscription_parametergroup_config["event_categories"])}"]
  tags             = "${merge(map("Name", "${var.tag_name_identifier}-${var.database_identifier}-db-parametergroup-event-subscription"),var.global_tags)}"
}

resource "random_string" "master_password" {
  length      = 16
  special     = false # avoid complexity with failures due to invalid chars
  upper       = true
  lower       = true
  number      = true
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}
