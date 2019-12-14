output "vpc_id" {
  value = "${module.network.vpc_id}"
}

output "vpc_s3_endpoint" {
  value = "${module.network.vpc_s3_endpoint}"
}

output "vpc_private_sg_id" {
  value = "${module.network.vpc_private_sg_id}"
}

output "vpc_public_sg_id" {
  value = "${module.network.vpc_public_sg_id}"
}

output "vpc_public_subnet_ids" {
  value = ["${module.network.vpc_public_subnet_ids}"]
}

output "vpc_cidr_block" {
  value = "${module.network.vpc_cidr_block}"
}

output "vpc_cidr_blocks" {
  value = "${module.network.vpc_cidr_blocks}"
}

output "vpc_private_subnet_ids" {
  value = ["${module.network.vpc_private_subnet_ids}"]
}

output "vpc_private_route_table" {
  value = ["${module.network.vpc_private_route_table}"]
}

output "vpc_public_route_table" {
  value = ["${module.network.vpc_public_route_table}"]
}

output "subnet_data_route_table" {
  value = ["${module.network.subnet_data_route_table}"]
}

output "subnet_data_subnet_ids" {
  value = ["${module.network.subnet_data_subnet_ids}"]
}

output "subnet_data_subnet_cidr_blocks" {
  value = ["${module.network.subnet_data_subnet_cidr_blocks}"]
}

output "subnet_data_nacl_id" {
  value = "${module.network.subnet_data_nacl_id}"
}

output "subnet_new_private_subnet_ids" {
  value = ["${module.network.subnet_new_private_subnet_ids}"]
}

output "subnet_new_private_subnet_cidr_blocks" {
  value = ["${module.network.subnet_new_private_subnet_cidr_blocks}"]
}

output "hybrid_subnet_cidr_blocks" {
  value = ["${module.network.hybrid_subnet_cidr_blocks}"]
}

output "vpc_s3_endpoint_cidr_blocks" {
  value = ["${module.network.vpc_s3_endpoint_cidr_blocks}"]
}

output "artifacts_s3_id" {
  value = "${module.s3-opa-artifacts.id}"
}

output "s3_opa_logs_id" {
  value = "${module.s3-opa-logs.id}"
}

output "s3_client_data_id" {
  value = "${module.s3-opa-client-data.id}"
}

output "s3_registry_data_id" {
  value = "${module.s3-opa-registry-data.id}"
}

output "s3_mstr_backups_id" {
  value = "${module.s3-mstr-backups.id}"
}

output "appstream_sg_id" {
  value = "${module.appstream.appstream_sg_id}"
}

output "orchestration_arn" {
  value = "${module.microstrategyonaws-base-updates.orchestration_arn}"
}

output "ca_public_cert_ssm_param_name" {
  value       = "${aws_ssm_parameter.ca_public_cert.name}"
  description = "SSM param name for CA public cert"
}

output "ca_private_key_ssm_param_name" {
  value       = "${aws_ssm_parameter.ca_private_key.name}"
  description = "SSM param name for CA private key"
}

output "redshift_service_access_role_id" {
  value       = "${module.redshift-service-access-role.id}"
  description = "ID (so called AROAID) of role for Redshift access to other AWS services"
}

output "redshift_service_access_role_arn" {
  value       = "${module.redshift-service-access-role.arn}"
  description = "ARN of role for Redshift access to other AWS services"
}

output "link_service_role_arn" {
  value       = "${module.link-service-role.arn}"
  description = "ARN of role for LINK access to OPA resources"
}

output "data_load_service_role_name" {
  value       = "${module.data-load-role.name}"
  description = "Name of the Data Load Service role"
}
