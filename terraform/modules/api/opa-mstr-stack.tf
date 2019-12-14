locals {
  # Name of the resource on the API Gateway - should to be short and descriptive
  opa_mstr_stack_api_resource = "opa-mstr-stack"
  opa_mstr_stack_api_method   = "ANY"

  opa_mstr_stack_lambda_function_name = "${var.env_prefix}-${var.project}-${local.opa_mstr_stack_api_resource}"
  opa_mstr_stack_lambda_description   = "OPA Lambda used to create/destroy MSTR stacks"

  # main entry point for the lambda function - needs to fit the pattern [python_script.handler_method]
  # otherwise lambda will throw an error that it's unable to find the main entry point
  opa_mstr_stack_lambda_handler = "opa.api.opa_mstr_stack.lambda_handler"

  opa_mstr_stack_lambda_security_group_ids = ["${aws_security_group.default.id}"]
}

data "aws_iam_policy_document" "api_method_opa_mstr_stack_policy" {
  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "cloudformation:DescribeStacks",
      "cloudformation:DeleteStack",
      "cloudformation:UpdateTerminationProtection",
    ]

    resources = ["arn:aws:cloudformation:${local.aws_region}:${local.account_id}:stack/env-*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "rds:Describe*",
      "rds:Delete*",
      "ec2:Describe*",
      "ec2:Terminate*",
      "ec2:Delete*",
      "ec2:Revoke*",
      "elasticloadbalancing:Delete*",
      "elasticloadbalancingv2:Delete*",
      "codedeploy:Delete*",
      "elasticfilesystem:Describe*",
      "elasticfilesystem:Delete*",
    ]

    resources = ["*"]
  }
}

module "api_method_opa_mstr_stack" {
  source = "../api-method/"

  api_name                     = "${aws_api_gateway_rest_api.api.name}"
  api_gateway_id               = "${aws_api_gateway_rest_api.api.id}"
  api_gateway_root_resource_id = "${aws_api_gateway_rest_api.api.root_resource_id}"
  api_resource                 = "${local.opa_mstr_stack_api_resource}"
  api_method                   = "${local.opa_mstr_stack_api_method}"
  api_stage_name               = "${var.stage_name}"

  lambda_description   = "${local.opa_mstr_stack_lambda_description}"
  lambda_function_name = "${local.opa_mstr_stack_lambda_function_name}"
  lambda_s3_bucket     = "${var.opa_api_source_code_s3_bucket}"
  lambda_s3_key        = "${var.opa_api_source_code_s3_key}"
  lambda_handler       = "${local.opa_mstr_stack_lambda_handler}"

  lambda_subnet_ids         = ["${var.private_subnet_ids}"]
  lambda_security_group_ids = ["${local.opa_mstr_stack_lambda_security_group_ids}"]

  #lambda_custom_managed_policies = "${local.opa_mstr_stack_lambda_custom_managed_policies}"
  lambda_environment_vars = "${local.environment_vars}"

  lambda_custom_inline_policy_count = 1

  lambda_custom_inline_policies = [
    {
      custom_inline_name   = "${local.opa_mstr_stack_lambda_function_name}-IAM-Access"
      custom_inline_policy = "${data.aws_iam_policy_document.api_method_opa_mstr_stack_policy.json}"
    },
  ]

  env_prefix  = "${var.env_prefix}"
  global_tags = "${var.global_tags}"
}
