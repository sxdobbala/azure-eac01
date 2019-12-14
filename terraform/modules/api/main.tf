data "aws_region" "current_region" {}

data "aws_caller_identity" "current_identity" {}

locals {
  aws_region   = "${data.aws_region.current_region.name}"
  api_base_url = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${local.aws_region}.amazonaws.com/${var.stage_name}"

  account_id = "${data.aws_caller_identity.current_identity.account_id}"

  extra_environment_vars = {
    OPA_MASTER_LAMBDA = "${local.opa_master_lambda_function_name}"
  }

  environment_vars = "${merge(var.environment_vars, local.extra_environment_vars)}"

  # Using local variable instead of env_prefix to be able to test tag filtering with local dev environments ("dev-joe" > "dev")
  environment = "${element(split("-", "${var.env_prefix}"), 0)}"
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.env_prefix}-${var.api_name}"
  description = "${var.api_description}"

  endpoint_configuration {
    types = ["PRIVATE"]
  }

  policy = "${var.api_policy}"
}
