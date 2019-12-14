locals {
  # each api method should have its own environment vars section
  environment_vars = {
    OPA_MASTER_HOST           = "dev-opa-master-rds.c7b5ndug34sc.us-east-1.rds.amazonaws.com"
    OPA_MASTER_PORT           = "5432"
    OPA_MASTER_DATABASE       = "opa_master"
    OPA_MASTER_USER           = "opa_admin"
    OPA_MASTER_PASSWORD_KEY   = "/dev/dev-opa-master.master-password"
    OPA_RELEASE_SNS_ROLE_ARN  = "${module.opa-release-setup.opa_release_sns_role_arn}"
    OPA_RELEASE_SNS_TOPIC_ARN = "${module.opa-release-setup.opa_release_sns_topic_arn}"
    ENV_PREFIX                = "${var.env_prefix}"
    ARTIFACTS_BUCKET          = "${local.artifacts_s3_id}"
    MSTR_BACKUPS_BUCKET       = "${data.terraform_remote_state.shared.s3_mstr_backups_id}"
    TF_BACKEND_BUCKET         = "760182235631-tfstate-nonprodoptumopa"
    TF_BACKEND_TABLE          = "760182235631-tflock-nonprodoptumopa"
    SCRIPT_RUNTIME            = "sh"
    SCRIPT_PATH               = "/opt/opa/install/"
  }
}

module "opa-release-setup" {
  source      = "../../modules/opa-release-setup"
  env_prefix  = "${var.env_prefix}"
  global_tags = "${local.global_tags}"
}

# Redshift egress security group
# Allows outbound traffic to data subnets
# Each redshift cluster's SG will then allow inbound traffic from this SG
resource "aws_security_group" "redshift_egress_sg" {
  name        = "${var.env_prefix}-redshift-egress-sg"
  description = "Security group for ${var.env_prefix} redshift egress"
  vpc_id      = "vpc-0a44c492a7e854b71"

  egress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["${data.terraform_remote_state.shared.subnet_data_subnet_cidr_blocks}"]
  }

  tags = "${merge(local.global_tags, map("Name", "${var.env_prefix}-redshift-egress-sg"))}"
}

module "opa-api" {
  source          = "../../modules/opa-api/"
  env_prefix      = "${var.env_prefix}"
  s3_artifacts_id = "${local.artifacts_s3_id}"
}

# create api gateway, api methods and associated lambdas
module "api" {
  source                      = "../../modules/api/"
  stage_name                  = "dev"
  environment_vars            = "${local.environment_vars}"
  api_policy                  = "${file("${path.module}/api-policy.json")}"
  data_load_service_role_name = "${data.terraform_remote_state.shared.data_load_service_role_name}"

  # NEW VPC
  vpc_id                        = "vpc-0a44c492a7e854b71"
  vpc_cidr_block                = ["10.250.166.0/24"]
  hybrid_cidr_block             = ["10.0.0.0/8"]
  private_subnet_ids            = ["subnet-00f78ad53569e7ae9", "subnet-01b9d46da2fe55aae"]
  env_prefix                    = "${var.env_prefix}"
  global_tags                   = "${local.global_tags}"
  redshift_egress_sg            = "${aws_security_group.redshift_egress_sg.id}"
  opa_api_source_code_s3_bucket = "${module.opa-api.opa_api_source_code_s3_bucket}"
  opa_api_source_code_s3_key    = "${module.opa-api.opa_api_source_code_s3_key}"
  opa_release_sns_role_arn      = "${module.opa-release-setup.opa_release_sns_role_arn}"
  artifacts_s3_id               = "${local.artifacts_s3_id}"
}
