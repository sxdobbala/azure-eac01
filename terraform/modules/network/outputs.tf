output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "vpc_s3_endpoint" {
  value = "${module.vpc.vpc_s3_endpoint}"
}

output "vpc_private_sg_id" {
  value = "${module.vpc.vpc_private_sg_id}"
}

output "vpc_public_sg_id" {
  value = "${module.vpc.vpc_public_sg_id}"
}

output "vpc_public_subnet_ids" {
  value = ["${module.vpc.vpc_public_subnet_ids}"]
}

output "vpc_cidr_block" {
  value = "${module.vpc.vpc_cidr_block}"
}

output "vpc_cidr_blocks" {
  value = ["${split(",", length(var.vpc_secondary_cidr_blocks) > 0 
    ? format("${module.vpc.vpc_cidr_block},%s", join(",", var.vpc_secondary_cidr_blocks))
    : module.vpc.vpc_cidr_block)}"]
}

output "vpc_private_subnet_ids" {
  value = ["${module.vpc.vpc_private_subnet_ids}"]
}

output "vpc_private_route_table" {
  value = ["${module.vpc.vpc_private_route_table}"]
}

output "vpc_public_route_table" {
  value = ["${module.vpc.vpc_public_route_table}"]
}

output "subnet_data_route_table" {
  value = ["${module.data-subnets.subnets_private_route_table}"]
}

output "subnet_data_subnet_ids" {
  value = ["${module.data-subnets.subnets_private_subnet_ids}"]
}

output "subnet_data_subnet_cidr_blocks" {
  value = ["${module.data-subnets.subnets_private_subnet_cidrs}"]
}

# if no new private subnets specified, return the original private subnet
output "subnet_new_private_subnet_ids" {
  value = ["${split(",", length(var.new_private_subnets_cidr_blocks) > 0 
    ? join(",", module.new-private-subnets.subnets_private_subnet_ids) 
    : join(",", module.vpc.vpc_private_subnet_ids))}"]
}

output "subnet_new_private_subnet_cidr_blocks" {
  value = ["${split(",", length(var.new_private_subnets_cidr_blocks) > 0 
    ? join(",", module.new-private-subnets.subnets_private_subnet_cidrs) 
    : join(",", module.vpc.vpc_private_subnet_cidrs))}"]
}

output "subnet_data_nacl_id" {
  value = "${module.data-subnets.subnets_private_nacl_id}"
}

output "vpc_private_nacl_id" {
  value = "${module.vpc.vpc_private_nacl_id}"
}

output "vpc_s3_endpoint_cidr_blocks" {
  value = ["${data.aws_vpc_endpoint.s3.cidr_blocks}"]
}

# Security group ID for the VPC endpoint granting access to the OPA API
output "api_gateway_vpce_sg_id" {
  value = "${aws_security_group.api_gateway_vpce_sg.id}"
}

output "vpc_nat_gateway" {
  value = ["${module.vpc.vpc_nat_gateway}"]
}

output "hybrid_subnet_cidr_blocks" {
  value = ["${local.hybrid_cidr_block}"]
}
