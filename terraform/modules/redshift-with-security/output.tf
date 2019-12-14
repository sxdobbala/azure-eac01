output "redshift_ingress_security_group_id" {
  value = "${module.redshift_instance.redshift_security_group_id}"
}

output "redshift_egress_security_group_id" {
  value = "${aws_security_group.redshift-sg-egress.id}"
}

output "redshift_port" {
  value = "${module.redshift_instance.redshift_cluster_port}"
}
