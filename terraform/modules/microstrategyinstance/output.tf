output "environment_id" {
  value = "${data.aws_ssm_parameter.environmentid.value}"
}
