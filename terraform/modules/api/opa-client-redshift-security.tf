locals {
  # Name of the resource on the API Gateway - should to be short and descriptive
  opa_client_redshift_security_api_resource = "opa-client-redshift-security"
  opa_client_redshift_security_api_method   = "ANY"

  opa_client_redshift_security_lambda_function_name = "${var.env_prefix}-${var.project}-${local.opa_client_redshift_security_api_resource}"
  opa_client_redshift_security_lambda_description   = "OPA Lambda for Redshift security group setup on MSTR instances"

  # main entry point for the lambda function - needs to fit the pattern [python_script.handler_method]
  # otherwise lambda will throw an error that it's unable to find the main entry point
  opa_client_redshift_security_lambda_handler = "opa.api.opa_client_redshift_security.lambda_handler"

  opa_client_redshift_security_lambda_security_group_ids = ["${aws_security_group.default.id}", "${var.redshift_egress_sg}"]
}

data "aws_iam_policy_document" "api_method_opa_client_redshift_security_policy" {
  statement {
    effect = "Allow"

    actions = [
      "iam:AttachRolePolicy",
    ]

    resources = ["arn:aws:iam::${local.account_id}:role/MSTRInstanceProfileRole-*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "iam:GetInstanceProfile",
    ]

    resources = ["arn:aws:iam::${local.account_id}:instance-profile/MicroStrategyOnAWS-*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "redshift:GetClusterCredentials",
      "redshift:DescribeClusters",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:ModifyInstanceAttribute"]
    resources = ["*"]
  }
}

module "api_method_opa_client_redshift_security" {
  source = "../api-method/"

  api_name                     = "${aws_api_gateway_rest_api.api.name}"
  api_gateway_id               = "${aws_api_gateway_rest_api.api.id}"
  api_gateway_root_resource_id = "${aws_api_gateway_rest_api.api.root_resource_id}"
  api_resource                 = "${local.opa_client_redshift_security_api_resource}"
  api_method                   = "${local.opa_client_redshift_security_api_method}"
  api_stage_name               = "${var.stage_name}"

  lambda_description   = "${local.opa_client_redshift_security_lambda_description}"
  lambda_function_name = "${local.opa_client_redshift_security_lambda_function_name}"
  lambda_s3_bucket     = "${var.opa_api_source_code_s3_bucket}"
  lambda_s3_key        = "${var.opa_api_source_code_s3_key}"
  lambda_handler       = "${local.opa_client_redshift_security_lambda_handler}"

  lambda_subnet_ids         = ["${var.private_subnet_ids}"]
  lambda_security_group_ids = ["${local.opa_client_redshift_security_lambda_security_group_ids}"]

  lambda_environment_vars = "${local.environment_vars}"

  lambda_custom_inline_policy_count = 1

  lambda_custom_inline_policies = [
    {
      custom_inline_name   = "${local.opa_client_redshift_security_lambda_function_name}-IAM-Access"
      custom_inline_policy = "${data.aws_iam_policy_document.api_method_opa_client_redshift_security_policy.json}"
    },
  ]

  env_prefix  = "${var.env_prefix}"
  global_tags = "${var.global_tags}"
}
