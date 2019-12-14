output "opa_rds_identifier" {
  value = "${aws_db_instance.default.id}"
}

# returns "host"
output "opa_rds_host" {
  value = "${aws_db_instance.default.address}"
}

# returns "port"
output "opa_rds_port" {
  value = "${aws_db_instance.default.port}"
}

# returns "host:port"
output "opa_rds_endpoint" {
  value = "${aws_db_instance.default.endpoint}"
}

output "opa_rds_database_name" {
  value = "${aws_db_instance.default.name}"
}

output "opa_rds_username" {
  value = "${aws_db_instance.default.username}"
}

output "opa_rds_password_key" {
  value = "${aws_ssm_parameter.master-password.name}"
}

output "opa_rds_engine_type" {
  value = "${aws_db_instance.default.engine}-${aws_db_instance.default.engine_version}"
}

output "opa_rds_security_group_id" {
  value = "${aws_db_instance.default.vpc_security_group_ids}"
}

output "opa_rds_parameter_group_name" {
  value = "${aws_db_instance.default.parameter_group_name}"
}

output "opa_rds_kms_key_for_db_encryption" {
  value = "${aws_db_instance.default.kms_key_id}"
}

output "opa_rds_event_subscriptions" {
  value = "${
          zipmap(
              aws_db_event_subscription.instance.*.name,aws_db_event_subscription.instance.*.sns_topic
          )
        }"
}

output "opa_rds_parametergroup_event_subscriptions" {
  value = "${
          zipmap(
              aws_db_event_subscription.parametergroup.*.name,aws_db_event_subscription.parametergroup.*.sns_topic
          )
        }"
}
