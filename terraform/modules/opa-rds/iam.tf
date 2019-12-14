module "create-role-for-enhanced-monitoring" {
  source                             = "git::https://github.optum.com/CommercialCloud-EAC/aws_iam.git//terraform_module/role?ref=v1.0.3"
  role_name                          = "${var.database_identifier}-enhanced-monitoring-${var.tag_name_identifier}"
  role_description                   = "Role for RDS enhanced monitoring"
  role_assumerole_service_principals = ["monitoring.rds.amazonaws.com"]
  role_custom_managed_policy_count   = 1
  role_custom_managed_policy         = ["arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"]

  global_tags = "${merge(map("Name", "${var.tag_name_identifier}-${var.database_identifier}-enhanced-monitoring"),var.global_tags)}"
}

module "create-default-role-for-rds" {
  source                             = "git::https://github.optum.com/CommercialCloud-EAC/aws_iam.git//terraform_module/role?ref=v1.0.3"
  role_name                          = "${var.database_identifier}-default-role-rds-${var.tag_name_identifier}"
  role_description                   = "Defalt role grant permission for the DB instance to access cloudwatch to send audit logs and alert to SNS"
  role_assumerole_service_principals = ["rds.amazonaws.com"]
  role_custom_managed_policy_count   = 1
  role_custom_managed_policy         = ["${module.create-managed-policy-for-rds-default-role.policy_arn}"]

  global_tags = "${merge(map("Name", "${var.tag_name_identifier}-${var.database_identifier}-default-role-rds"),var.global_tags)}"
}

module "create-managed-policy-for-rds-default-role" {
  source             = "git::https://github.optum.com/CommercialCloud-EAC/aws_iam.git//terraform_module/policy?ref=v1.0.3"
  policy_name        = "${var.database_identifier}-managed-policy-for-rds-default-role-${var.tag_name_identifier}"
  policy_path        = "/"
  policy_description = "Policy for Default RDS role"
  policy_document    = "${data.aws_iam_policy_document.managed-policy-for-rds-default-role.json}"
}

data "aws_iam_policy_document" "managed-policy-for-rds-default-role" {
  statement {
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]

    resources = ["arn:aws:sns:${data.aws_region.current_region.name}:${data.aws_caller_identity.current_identity.account_id}:*"]
  }
}
