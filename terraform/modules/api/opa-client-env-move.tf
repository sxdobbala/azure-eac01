locals {
  # Name of the resource on the API Gateway - should to be short and descriptive
  opa_client_env_move_api_resource = "opa-client-env-move"
  opa_client_env_move_api_method   = "ANY"

  opa_client_env_move_lambda_function_name = "${var.env_prefix}-${var.project}-${local.opa_client_env_move_api_resource}"
  opa_client_env_move_lambda_description   = "OPA Lambda to update OPA Master when rotating all clients from one environment to another"

  # main entry point for the lambda function - needs to fit the pattern [python_script.handler_method]
  # otherwise lambda will throw an error that it's unable to find the main entry point
  opa_client_env_move_lambda_handler = "opa.api.opa_client_env_move.lambda_handler"

  opa_client_env_move_lambda_security_group_ids = ["${aws_security_group.default.id}"]
}

data "aws_iam_policy_document" "api_method_opa_client_env_move_policy" {
  statement {
    effect    = "Allow"
    actions   = ["tag:GetResources", "tag:TagResources"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = ["ec2:CreateTags"]
    resources = ["*"]
  }
}

module "api_method_opa_client_env_move" {
  source = "../api-method/"

  api_name                     = "${aws_api_gateway_rest_api.api.name}"
  api_gateway_id               = "${aws_api_gateway_rest_api.api.id}"
  api_gateway_root_resource_id = "${aws_api_gateway_rest_api.api.root_resource_id}"
  api_resource                 = "${local.opa_client_env_move_api_resource}"
  api_method                   = "${local.opa_client_env_move_api_method}"
  api_stage_name               = "${var.stage_name}"

  lambda_description   = "${local.opa_client_env_move_lambda_description}"
  lambda_function_name = "${local.opa_client_env_move_lambda_function_name}"
  lambda_s3_bucket     = "${var.opa_api_source_code_s3_bucket}"
  lambda_s3_key        = "${var.opa_api_source_code_s3_key}"
  lambda_handler       = "${local.opa_client_env_move_lambda_handler}"

  lambda_subnet_ids         = ["${var.private_subnet_ids}"]
  lambda_security_group_ids = ["${local.opa_client_env_move_lambda_security_group_ids}"]
  lambda_environment_vars   = "${local.environment_vars}"

  lambda_custom_inline_policy_count = 1

  lambda_custom_inline_policies = [
    {
      custom_inline_name   = "${local.opa_client_env_move_lambda_function_name}"
      custom_inline_policy = "${data.aws_iam_policy_document.api_method_opa_client_env_move_policy.json}"
    },
  ]

  env_prefix  = "${var.env_prefix}"
  global_tags = "${var.global_tags}"
}
