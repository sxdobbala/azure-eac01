locals {
  namespace              = "${var.env_prefix == "ci" ? "mstr-ci" : "mstr"}"
  name_suffix            = "${var.env_prefix == "ci" ? "artifacts" : "mstronaws-artifacts"}"
  log_bucket_name_suffix = "${var.env_prefix == "ci" ? "logs" : "mstronaws-logs"}"
  rep_bucket_name_suffix = "${var.env_prefix == "ci" ? "repl" : "mstronaws-replication"}"

  dummy_map = {
    "CloudOrchestratorSNSTopic" = "${aws_sns_topic.microstrategyonaws-dummy-topic.arn}"
  }

  stack_outputs = "${merge(local.dummy_map, aws_cloudformation_stack.MicroStrategyOnAWS.outputs)}"
}

data "aws_region" "current" {}

module "s3-mstr-artifacts" {
  source                   = "git::https://github.optum.com/CommercialCloud-EAC/aws_s3.git//modules/rep-log?ref=v2.1.2"
  name_suffix              = "${local.name_suffix}"
  log_bucket_name_suffix   = "${local.log_bucket_name_suffix}"
  rep_bucket_name_suffix   = "${local.rep_bucket_name_suffix}"
  custom_policy            = ""
  force_destroy            = true
  log_bucket_force_destroy = true
  rep_bucket_force_destroy = true
  sse_algorithm            = "aes256"
  tags                     = "${merge(var.global_tags, map("Name", "mstronaws-artifacts"))}"
}

resource "random_uuid" "cloudformation_dependency_workaround" {
  keepers = {
    timestamp = "${timestamp()}"
  }

  # Until we have a way to detect whether the CF stack was actually modified or not,
  #   run idempotent post-update Python scripts on every iteration
  # 
  # but ensure that we run after CF if it actually does change
  depends_on = ["aws_cloudformation_stack.MicroStrategyOnAWS"]
}

resource "null_resource" "updatebasecloudformationsecurity" {
  triggers = {
    s3_bucket          = "${module.s3-mstr-artifacts.id}"
    ingress_cidr_block = "${var.ingress_cidr_block}"
    vpc_cidr_block     = "${var.vpc_cidr_block}"
    vpc                = "${var.vpc}"
    force_every_time   = "${random_uuid.cloudformation_dependency_workaround.result}"
  }

  provisioner "local-exec" {
    command     = "python3 -m venv venv"
    working_dir = "${path.module}"
    on_failure  = "fail"
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    command     = ". venv/bin/activate;python3 -m pip install -r requirements.txt"
    working_dir = "${path.module}"
    on_failure  = "fail"
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    command     = ". venv/bin/activate;python3 updatebasecloudformationsecurity.py --s3bucket ${module.s3-mstr-artifacts.id}  --ingresscidrblock ${var.ingress_cidr_block} --vpccidr ${var.vpc_cidr_block} --vpc ${var.vpc}  --publicsubnet01 ${var.publicsubnet01} --publicsubnet02 ${var.publicsubnet02} --privatesubnet01 ${var.privatesubnet01} --privatesubnet02 ${var.privatesubnet02}"
    working_dir = "${path.module}"
    on_failure  = "fail"
    interpreter = ["bash", "-c"]
  }

  depends_on = ["module.s3-mstr-artifacts"]
}

data "archive_file" "update_optum_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/MSTR_UpdateOptum.py"
  output_path = "${path.module}/archives/MSTR_UpdateOptum.zip"
}

module "update_optum_lambda" {
  source        = "git::https://github.optum.com/CommercialCloud-EAC/aws_lambda.git?ref=v2.0.0"
  function_name = "MSTR_UpdateOptum"
  description   = "MSTR Update Optum Params"
  namespace     = "${local.namespace}"
  filename      = "${data.archive_file.update_optum_lambda_zip.output_path}"

  global_tags = "${var.global_tags}"
}

data "archive_file" "update_security_groups_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/MSTR_UpdateSecurityGroups.py"
  output_path = "${path.module}/archives/MSTR_UpdateSecurityGroups.zip"
}

module "update_security_groups_lambda" {
  source        = "git::https://github.optum.com/CommercialCloud-EAC/aws_lambda.git?ref=v2.0.0"
  function_name = "MSTR_UpdateSecurityGroups"
  description   = "MSTR Update security groups"
  namespace     = "${local.namespace}"
  filename      = "${data.archive_file.update_security_groups_lambda_zip.output_path}"

  environment_vars = {
    INGRESS_CIDR_BLOCK = "${var.ingress_cidr_block}"
    APPSTREAM_SG_ID    = "${var.appstream_sg_id}"
    IS_PROD            = "${var.is_prod}"
  }

  global_tags = "${var.global_tags}"
}

data "archive_file" "update_ami_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/MSTR_UpdateAMI.py"
  output_path = "${path.module}/archives/MSTR_UpdateAMI.zip"
}

data "aws_iam_policy_document" "lambda_allow_describe_images" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeImages",
    ]

    resources = ["*"]
  }
}

module "update_ami_lambda" {
  source                     = "git::https://github.optum.com/CommercialCloud-EAC/aws_lambda.git?ref=v2.0.0"
  function_name              = "MSTR_UpdateAMI"
  description                = "MSTR Update AMI"
  namespace                  = "${local.namespace}"
  filename                   = "${data.archive_file.update_ami_lambda_zip.output_path}"
  custom_inline_policy_count = 1

  custom_inline_policies = [
    {
      custom_inline_name   = "LambdaDescribeImages"
      custom_inline_policy = "${data.aws_iam_policy_document.lambda_allow_describe_images.json}"
    },
  ]

  global_tags = "${var.global_tags}"
}

resource "aws_ssm_parameter" "microstrategy_master" {
  name      = "/microstrategy/master"
  type      = "String"
  overwrite = true
  value     = "{\n \"CustomLambdasARN\":\n  [\n   \"${module.update_security_groups_lambda.arn}\",\n   \"${module.update_ami_lambda.arn}\",\n   \"${module.update_optum_lambda.arn}\"\n  ]\n}"
  tags      = "${var.global_tags}"

  depends_on = ["aws_cloudformation_stack.MicroStrategyOnAWS"]
}

resource "aws_cloudformation_stack" "MicroStrategyOnAWS" {
  name         = "MicroStrategyOnAWS"
  capabilities = ["CAPABILITY_NAMED_IAM"]
  template_url = "${var.mstr_aws_cloudformation_stack_template_url}"

  parameters = {
    VPC             = "${var.vpc}"
    VPCCidrBlock    = "${var.vpc_cidr_block}"
    PublicSubnet01  = "${var.publicsubnet01}"
    PublicSubnet02  = "${var.publicsubnet02}"
    PrivateSubnet01 = "${var.privatesubnet01}"
    PrivateSubnet02 = "${var.privatesubnet02}"
  }

  tags = "${var.global_tags}"
}

# if/when the stack creation fails, the stack has no outputs
# so we can use this dummy sns topic for output so that "tf plan" doesn't break
resource "aws_sns_topic" "microstrategyonaws-dummy-topic" {
  name = "microstrategyonaws-dummy-topic"
}
