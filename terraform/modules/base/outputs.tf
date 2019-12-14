output "redshift_egress_sg_id" {
  value = "${aws_security_group.redshift_egress_sg.id}"
}

output "opa_release_sns_topic_arn" {
  value = "${module.opa-release-setup.opa_release_sns_topic_arn}"
}
