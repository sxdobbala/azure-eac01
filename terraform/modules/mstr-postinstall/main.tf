locals {
  prefix                               = "${var.env_prefix != "" ? "${var.env_prefix}-" : ""}"
  mstr_postinstall_codedeploy_key      = "${local.prefix}mstr-postinstall-codedeploy.zip"
  mstr_postinstall_codedeploy_app_name = "MSTRCodeDeploy"
  codedeploy_config_name               = "CodeDeployDefault.OneAtATime"
  aws_account_id                       = "${data.aws_caller_identity.current.account_id}"
}

data "aws_caller_identity" "current" {}

module "postinstall_lambda" {
  source = "git::https://github.optum.com/CommercialCloud-EAC/aws_lambda.git?ref=v2.0.0"

  function_name = "${var.env_prefix}-mstr-postinstall"
  description   = "Run Steps after MSTR installation"
  handler       = "opa.exec.mstr_postinstall.lambda_handler"
  s3_bucket     = "${var.opa_api_source_code_s3_bucket}"
  s3_key        = "${var.opa_api_source_code_s3_key}"

  environment_vars = {
    ENV_PREFIX                           = "${var.env_prefix}"
    S3_BUCKET_ID                         = "${var.artifacts_s3_bucket}"
    MSTR_POSTINSTALL_CODEDEPLOY_KEY      = "${local.mstr_postinstall_codedeploy_key}"
    MSTR_POSTINSTALL_CODEDEPLOY_APP_NAME = "${local.mstr_postinstall_codedeploy_app_name}"
    DATALOADER_EGRESS_SG_ID              = "${var.dataloader_egress_sg_id}"
    GLOBAL_TAGS                          = "${jsonencode(var.global_tags)}"
  }

  custom_inline_policy_count = 1

  custom_inline_policies = [
    {
      custom_inline_name   = "LambdaRunSSM"
      custom_inline_policy = "${data.aws_iam_policy_document.postinstall_lambda_policy.json}"
    },
  ]

  global_tags = "${var.global_tags}"
}

data "aws_iam_policy_document" "postinstall_lambda_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:SendCommand", "ssm:GetCommandInvocation", "ec2:CreateTags"]
    resources = ["arn:aws:ec2:${var.aws_region}:${local.aws_account_id}:instance/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeInstanceStatus"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetCommandInvocation", "ssm:SendCommand"]
    resources = ["arn:aws:ssm:${var.aws_region}:*:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["cloudformation:DescribeStacks", "cloudformation:DescribeStackResource"]
    resources = ["arn:aws:cloudformation:${var.aws_region}:${local.aws_account_id}:stack/env-*/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["codedeploy:CreateDeployment"]
    resources = ["arn:aws:codedeploy:${var.aws_region}:${local.aws_account_id}:deploymentgroup:${local.mstr_postinstall_codedeploy_app_name}/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["codedeploy:GetDeploymentConfig"]
    resources = ["arn:aws:codedeploy:${var.aws_region}:${local.aws_account_id}:deploymentconfig:${local.codedeploy_config_name}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["codedeploy:RegisterApplicationRevision", "codedeploy:GetApplicationRevision"]
    resources = ["arn:aws:codedeploy:${var.aws_region}:${local.aws_account_id}:application:${local.mstr_postinstall_codedeploy_app_name}"]
  }

  statement {
    effect  = "Allow"
    actions = ["ssm:GetParameter"]

    resources = [
      "arn:aws:ssm:${var.aws_region}:${local.aws_account_id}:parameter/env-*/customer",
      "arn:aws:ssm:${var.aws_region}:${local.aws_account_id}:parameter/env-*/env_prefix",
      "arn:aws:ssm:${var.aws_region}:${local.aws_account_id}:parameter/env-*/elb_path",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["ssm:PutParameter"]
    resources = ["arn:aws:ssm:${var.aws_region}:${local.aws_account_id}:parameter/${var.env_prefix}/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["tag:GetResources", "tag:TagResources"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:ModifyInstanceAttribute",
    ]

    resources = ["*"]
  }
}

##codedeploy

resource "aws_sns_topic" "mstrcodedeploy" {
  name = "${lower(local.mstr_postinstall_codedeploy_app_name)}"
}

data "archive_file" "codedeploy" {
  type        = "zip"
  source_dir  = "${path.module}/codedeploy"
  output_path = "${path.module}/archive/${local.mstr_postinstall_codedeploy_key}"

  depends_on = [
    "local_file.env_vars",
  ]
}

resource "aws_s3_bucket_object" "codedeploy_object" {
  bucket = "${var.artifacts_s3_bucket}"
  key    = "${local.mstr_postinstall_codedeploy_key}"
  source = "${data.archive_file.codedeploy.output_path}"
  etag   = "${data.archive_file.codedeploy.output_md5}"
  tags   = "${var.global_tags}"
}

data "template_file" "env_vars_template" {
  template = "${file("${path.module}/codedeploy/resources/env_vars_template.yaml")}"

  vars = {
    bucket_name = "${local.aws_account_id}-opa-flat-files"
    env_prefix  = "${var.env_prefix}"
  }
}

resource "local_file" "env_vars" {
  content  = "${data.template_file.env_vars_template.rendered}"
  filename = "${path.module}/codedeploy/vars/env_vars.yaml"
}
