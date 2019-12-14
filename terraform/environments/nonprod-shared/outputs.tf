output "vpc_id" {
  value = "${module.base-shared.vpc_id}"
}

output "vpc_s3_endpoint" {
  value = "${module.base-shared.vpc_s3_endpoint}"
}

output "vpc_private_sg_id" {
  value = "${module.base-shared.vpc_private_sg_id}"
}

output "vpc_public_sg_id" {
  value = "${module.base-shared.vpc_public_sg_id}"
}

output "vpc_public_subnet_ids" {
  value = ["${module.base-shared.vpc_public_subnet_ids}"]
}

output "vpc_cidr_block" {
  value = "${module.base-shared.vpc_cidr_block}"
}

output "vpc_cidr_blocks" {
  value = "${module.base-shared.vpc_cidr_blocks}"
}

output "vpc_private_subnet_ids" {
  value = ["${module.base-shared.vpc_private_subnet_ids}"]
}

output "vpc_private_route_table" {
  value = ["${module.base-shared.vpc_private_route_table}"]
}

output "vpc_public_route_table" {
  value = ["${module.base-shared.vpc_public_route_table}"]
}

output "subnet_data_route_table" {
  value = ["${module.base-shared.subnet_data_route_table}"]
}

output "subnet_data_subnet_ids" {
  value = ["${module.base-shared.subnet_data_subnet_ids}"]
}

output "subnet_data_subnet_cidr_blocks" {
  value = ["${module.base-shared.subnet_data_subnet_cidr_blocks}"]
}

output "subnet_data_nacl_id" {
  value = "${module.base-shared.subnet_data_nacl_id}"
}

output "subnet_new_private_subnet_ids" {
  value = ["${module.base-shared.subnet_new_private_subnet_ids}"]
}

output "subnet_new_private_subnet_cidr_blocks" {
  value = ["${module.base-shared.subnet_new_private_subnet_cidr_blocks}"]
}

output "hybrid_subnet_cidr_blocks" {
  value = ["${module.base-shared.hybrid_subnet_cidr_blocks}"]
}

output "vpc_s3_endpoint_cidr_blocks" {
  value = ["${module.base-shared.vpc_s3_endpoint_cidr_blocks}"]
}

output "artifacts_s3_id" {
  value = "${module.base-shared.artifacts_s3_id}"
}

output "s3_opa_logs_id" {
  value = "${module.base-shared.s3_opa_logs_id}"
}

output "s3_client_data_id" {
  value = "${module.base-shared.s3_client_data_id}"
}

output "s3_registry_data_id" {
  value = "${module.base-shared.s3_registry_data_id}"
}

output "s3_mstr_backups_id" {
  value = "${module.base-shared.s3_mstr_backups_id}"
}

output "appstream_sg_id" {
  value = "${module.base-shared.appstream_sg_id}"
}

output "orchestration_arn" {
  value = "${module.base-shared.orchestration_arn}"
}

output "ca_public_cert_ssm_param_name" {
  value       = "${module.base-shared.ca_public_cert_ssm_param_name}"
  description = "SSM param name for CA public cert"
}

output "ca_private_key_ssm_param_name" {
  value       = "${module.base-shared.ca_private_key_ssm_param_name}"
  description = "SSM param name for CA private key"
}

output "redshift_service_access_role_arn" {
  value       = "${module.base-shared.redshift_service_access_role_arn}"
  description = "ARN of role for Redshift access to other AWS services"
}

output "link_service_role_arn" {
  value       = "${module.base-shared.link_service_role_arn}"
  description = "ARN of role for LINK access to OPA resources"
}

output "data_load_service_role_name" {
  value       = "${module.base-shared.data_load_service_role_name}"
  description = "Name of the Data Load Service role"
}
