#!/usr/bin/env python3
from terraformrunner import Terraform
import json
import pytest
import boto3
import os
import shutil


class Test_modules:
    def test_hybridnetwork_module(self):
        virtual_interface_id = "blah-1234"
        args = {
            "vpc_cidr_block": "10.250.166.0/24",
            "aws_region": "us-east-1",
            "aws_azs": ["us-east-1a", "us-east-1b"],
            "az_count": "2",
            "network_name": "testnetwork",
            "virtual_interface_id": virtual_interface_id,
            "private_subnets_cidr_blocks": ["10.250.166.0/26", "10.250.166.64/26"],
            "public_subnets_cidr_blocks": ["10.250.166.128/28", "10.250.166.144/28"],
            "data_subnets_cidr_blocks": ["10.250.166.160/27", "10.250.166.192/27"],
            "dataports_count": "1",
            "dataports": ["5439"],
        }
        match_list = {
            "module.test.aws_dx_hosted_private_virtual_interface_accepter.dx_accepter": {
                "id": "<computed>",
                "arn": "<computed>",
                "tags.%": "1",
                "tags.Side": "Accepter",
                "virtual_interface_id": virtual_interface_id,
                "vpn_gateway_id": "${aws_vpn_gateway.hybrid_gateway.id}",
            },
            "module.test.module.network.module.vpc.module.vpc-subnets.aws_subnet.public[0]": {
                "id": "<computed>",
                "arn": "<computed>",
                "assign_ipv6_address_on_creation": "false",
                "availability_zone": "us-east-1a",
                "availability_zone_id": "<computed>",
                "cidr_block": "10.250.166.128/28",
                "ipv6_cidr_block": "<computed>",
                "ipv6_cidr_block_association_id": "<computed>",
                "map_public_ip_on_launch": "false",
                "owner_id": "<computed>",
                "tags.%": "2",
                "tags.Name": "testnetwork-public-subnets",
                "tags.terraform": "true",
                "vpc_id": "${var.vpc_id}",
            },
        }

        self.check_module("hybridnetwork", 87, args, match_list, 1)

    def test_network_module(self):
        args = {
            "vpc_cidr_block": "10.250.166.0/24",
            "aws_region": "us-east-1",
            "aws_azs": ["us-east-1a", "us-east-1b"],
            "az_count": "2",
            "network_name": "testnetwork",
            "private_subnets_cidr_blocks": ["10.250.166.0/26", "10.250.166.64/26"],
            "public_subnets_cidr_blocks": ["10.250.166.128/28", "10.250.166.144/28"],
            "data_subnets_cidr_blocks": ["10.250.166.160/27", "10.250.166.192/27"],
            "dataports_count": "1",
            "dataports": ["5439"],
        }
        match_list = {
            "module.test.module.vpc.module.vpc-subnets.aws_subnet.public[0]": {
                "id": "<computed>",
                "arn": "<computed>",
                "assign_ipv6_address_on_creation": "false",
                "availability_zone": "us-east-1a",
                "availability_zone_id": "<computed>",
                "cidr_block": "10.250.166.128/28",
                "ipv6_cidr_block": "<computed>",
                "ipv6_cidr_block_association_id": "<computed>",
                "map_public_ip_on_launch": "false",
                "owner_id": "<computed>",
                "tags.%": "2",
                "tags.Name": "testnetwork-public-subnets",
                "tags.terraform": "true",
                "vpc_id": "${var.vpc_id}",
            },
            "module.test.module.vpc.aws_vpc.main": {
                "id": "<computed>",
                "arn": "<computed>",
                "assign_generated_ipv6_cidr_block": "false",
                "cidr_block": "10.250.166.0/24",
                "default_network_acl_id": "<computed>",
                "default_route_table_id": "<computed>",
                "tags.%": "2",
                "tags.Name": "testnetwork-vpc",
                "tags.terraform": "true",
            },
        }

        self.check_module("network", 71, args, match_list, 1)

    def test_hybridredshift_module(self):
        args = {
            "label": "test",
            "vpc_id": "test",
            "subnet_ids": ["test"],
            "subnet_cidr_blocks": ["0.0.0.0/0"],
            "database_name": "test",
            "aws_az": "",
            "number_of_nodes": "1",
            "master_username": "test",
            "master_password": "Test1234!",
            "cluster_type": "single-node",
            "snapshot_identifier": "test-snapshot",
            "final_snapshot_identifier": "test-final-snapshot-dev",
            "enhanced_vpc_routing ": "true",
            "hybrid_subnet_cidr_blocks": ["10.0.0.0/8"],
            "vpc_s3_endpoint_cidr_blocks ": ["10.0.0.1/32"],
        }
        match_list = {
            "module.test.aws_security_group_rule.redshift-sg-ingress-allow-hybrid-subnets": {
                "id": "<computed>",
                "cidr_blocks.0": "10.0.0.0/8",
                "type": "ingress",
                "from_port": "5439",
                "to_port": "5439",
                "security_group_id": "${module.redshiftinstance-with-security.redshift_ingress_security_group_id}",
            },
            "module.test.module.redshiftinstance-with-security.module.redshift_instance.aws_redshift_cluster.redshift-cluster": {
                "id": "<computed>",
                "cluster_identifier": "test-redshift-cluster",
            },
        }
        self.check_module("hybridredshift", 28, args, match_list)

    def test_redshift_with_security_module(self):
        args = {
            "label": "test",
            "vpc_id": "test",
            "subnet_ids": ["test"],
            "subnet_cidr_blocks": ["0.0.0.0/0"],
            "database_name": "test",
            "aws_az": "",
            "number_of_nodes": "1",
            "master_username": "test",
            "master_password": "Test1234!",
            "cluster_type": "single-node",
            "snapshot_identifier": "test-snapshot",
            "final_snapshot_identifier": "test-final-snapshot-dev",
            "enhanced_vpc_routing ": "true",
            "vpc_s3_endpoint_cidr_blocks ": ["10.0.0.1/32"],
        }
        match_list = {
            "module.test.module.redshift_instance.aws_redshift_cluster.redshift-cluster": {
                "id": "<computed>",
                "cluster_identifier": "test-redshift-cluster",
            }
        }

        self.check_module("redshift-with-security", 26, args, match_list)

    def test_microstrategyonaws_base_updates(self):
        args = {
            "vpc_cidr_block": "0.0.0.0/0",
            "vpc": "test",
            "publicsubnet01": "test",
            "publicsubnet02": "test",
            "privatesubnet01": "test",
            "privatesubnet02": "test",
            "ingress_cidr_block": "10.0.0.0",
        }
        match_list = {
            "module.test.aws_s3_bucket_object.MSTRCloudCreate_BuildCloudFormationParameters": {
                "id": "<computed>",
                "bucket": "${module.s3-mstr-artifacts.id}",
            },
            "module.test.module.s3-mstr-artifacts.aws_s3_bucket.bucket": {},
        }

        self.check_module("microstrategyonaws-base-updates", 28, args, match_list)

    def check_module(
        self, module_name, created, args, match_list, changed=0, destroyed=0
    ):
        hcl_args = ""
        for key, val in args.items():
            hcl_args += "  "
            hcl_args += key
            hcl_args += "="
            if isinstance(val, list):
                hcl_args += '["'
                hcl_args += '","'.join(val)
                hcl_args += '"]'
            else:
                hcl_args += '"'
                hcl_args += val
                hcl_args += '"'
            hcl_args += "\n"

        hcl = (
            'provider "aws" {  \n'
            '  region     = "us-east-1"\n'
            '  version    = "1.55.0"\n'
            "}\n"
            'provider "aws" {  \n'
            '  region     = "us-west-1"\n'
            '  alias    = "replication"\n'
            "}\n"
            'module "test" \n{\n'
            '  source = "../../terraform/modules/' + module_name + '"\n'
            "" + hcl_args + "\n"
            "}"
        )

        self.check_hcl(hcl, created, match_list, changed, destroyed)

    def check_hcl(self, hcl, created, match_list, changed, destroyed):
        directory = "fixture/"
        self.ensure_dir(directory)
        with open(directory + "/inline-hcl.tf", "w") as text_file:
            text_file.write(hcl)

        terraform = Terraform(directory)
        terraform.init()
        terraform.plan()
        try:
            terraform.destroy()
        except:
            print("exception in destroy")
        terraform.test_valid()
        terraform.test_counts(created, changed, destroyed)
        terraform.test_matches(match_list)
        shutil.rmtree(directory)

    def ensure_dir(self, file_path):
        directory = os.path.dirname(file_path)
        if os.path.exists(directory):
            shutil.rmtree(directory)
        os.makedirs(directory)
