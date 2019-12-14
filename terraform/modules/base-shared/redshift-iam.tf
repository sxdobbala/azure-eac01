module "redshift-service-access-role" {
  source                         = "git::https://github.optum.com/CommercialCloud-EAC/aws_iam.git//modules/iam-role?ref=v2.0.0"
  name                           = "redshift-service-access-role"
  description                    = "Role for Redshift access to other AWS services"
  assume_role_service_principals = ["redshift.amazonaws.com"]
  custom_managed_policy_count    = 1
  custom_managed_policy          = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]

  global_tags = "${var.global_tags}"
}
