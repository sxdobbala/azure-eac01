data "aws_caller_identity" "current_identity" {}
data "aws_region" "current_region" {}

locals {
  aws_account_id = "${data.aws_caller_identity.current_identity.account_id}"
}

# Using data here since these roles are guaranteed to be available as part of AWS account provisioning by CommercialCloud
data "aws_iam_role" "admins_role" {
  name = "AWS_${local.aws_account_id}_Admins"
}

data "aws_iam_role" "service_role" {
  name = "AWS_${local.aws_account_id}_Service"
}

data "aws_iam_role" "users_role" {
  name = "AWS_${local.aws_account_id}_Users"
}

# This role is created as part of MicroStrategyOnAWS stack
data "aws_iam_role" "mstr_ec2_role" {
  name = "MSTRInstanceProfileRole-us-east-1"
}
