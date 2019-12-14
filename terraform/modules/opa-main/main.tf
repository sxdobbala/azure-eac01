locals {
  codedeploy_app_name    = "${var.env_prefix}-OPA"
  codedeploy_config_name = "CodeDeployDefault.OneAtATime"
  lambda_deploy_opa_name = "${var.env_prefix}-deploy-opa"
}

data "aws_caller_identity" "current" {}

# BEGIN: OPA CodeDeploy app
resource "aws_codedeploy_app" "opa" {
  name = "${local.codedeploy_app_name}"
}

# END: OPA CodeDeploy app

# BEGIN: Lambda deploy_opa
module "lambda_deploy_opa" {
  source        = "git::https://github.optum.com/CommercialCloud-EAC/aws_lambda.git?ref=v2.0.0"
  function_name = "${local.lambda_deploy_opa_name}"
  description   = "Deploys opa to a given mstr environment"
  s3_bucket     = "${var.opa_api_source_code_s3_bucket}"
  s3_key        = "${var.opa_api_source_code_s3_key}"
  handler       = "opa.exec.deploy_opa.lambda_handler"

  environment_vars = {
    S3_BUCKET_ID                    = "${var.artifacts_s3_bucket}"
    CODEDEPLOY_APPLICATION          = "${local.codedeploy_app_name}"
    DEPLOYMENT_GROUP_NAME_FORMATTER = "${local.codedeploy_app_name}-{0}-platform"
    ENV_PREFIX                      = "${var.env_prefix}"
    OPA_RELEASE_S3_PREFIX           = "${var.opa_release_s3_prefix}"
  }

  custom_inline_policy_count = 1

  custom_inline_policies = [
    {
      custom_inline_name   = "CodeDeploy"
      custom_inline_policy = "${data.aws_iam_policy_document.lambda_deploy_opa_policy.json}"
    },
  ]

  global_tags = "${var.global_tags}"
}

data "aws_iam_policy_document" "lambda_deploy_opa_policy" {
  statement {
    effect  = "Allow"
    actions = ["codedeploy:CreateDeployment"]

    # TODO: Try to restrict access to deployment group based on dev/QA/Stage/Prod type of environment that the lambda belongs to
    resources = ["arn:aws:codedeploy:${var.aws_region}:${data.aws_caller_identity.current.account_id}:deploymentgroup:${local.codedeploy_app_name}/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["codedeploy:GetDeploymentConfig"]
    resources = ["arn:aws:codedeploy:${var.aws_region}:${data.aws_caller_identity.current.account_id}:deploymentconfig:${local.codedeploy_config_name}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["codedeploy:RegisterApplicationRevision", "codedeploy:GetApplicationRevision"]
    resources = ["arn:aws:codedeploy:${var.aws_region}:${data.aws_caller_identity.current.account_id}:application:${local.codedeploy_app_name}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ssm:PutParameter"]
    resources = ["arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.env_prefix}/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["cloudformation:DescribeStacks", "cloudformation:DescribeStackResource"]
    resources = ["arn:aws:cloudformation:${var.aws_region}:${data.aws_caller_identity.current.account_id}:stack/env-*/*"]
  }
}

# END: Lambda deploy_opa

