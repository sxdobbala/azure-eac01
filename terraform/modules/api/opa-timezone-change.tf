locals {
  # Name of the resource on the API Gateway - should to be short and descriptive
  opa_timezone_change_api_resource = "opa-timezone-change"
  opa_timezone_change_api_method   = "ANY"

  opa_timezone_change_lambda_function_name = "${var.env_prefix}-${var.project}-${local.opa_timezone_change_api_resource}"
  opa_timezone_change_lambda_description   = "OPA Lambda to update a MSTR environment to the EST/EDT timezone"

  # main entry point for the lambda function - needs to fit the pattern [python_script.handler_method]
  # otherwise lambda will throw an error that it's unable to find the main entry point
  opa_timezone_change_lambda_handler = "opa.api.opa_timezone_change.lambda_handler"

  opa_timezone_change_lambda_security_group_ids = ["${aws_security_group.default.id}"]
}

module "api_method_opa_timezone_change" {
  source = "../api-method/"

  api_name                     = "${aws_api_gateway_rest_api.api.name}"
  api_gateway_id               = "${aws_api_gateway_rest_api.api.id}"
  api_gateway_root_resource_id = "${aws_api_gateway_rest_api.api.root_resource_id}"
  api_resource                 = "${local.opa_timezone_change_api_resource}"
  api_method                   = "${local.opa_timezone_change_api_method}"
  api_stage_name               = "${var.stage_name}"

  lambda_description   = "${local.opa_timezone_change_lambda_description}"
  lambda_function_name = "${local.opa_timezone_change_lambda_function_name}"
  lambda_s3_bucket     = "${var.opa_api_source_code_s3_bucket}"
  lambda_s3_key        = "${var.opa_api_source_code_s3_key}"
  lambda_handler       = "${local.opa_timezone_change_lambda_handler}"

  lambda_subnet_ids         = ["${var.private_subnet_ids}"]
  lambda_security_group_ids = ["${local.opa_timezone_change_lambda_security_group_ids}"]
  lambda_environment_vars   = "${local.environment_vars}"

  env_prefix  = "${var.env_prefix}"
  global_tags = "${var.global_tags}"
}
