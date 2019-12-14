locals {
  # Name of the resource on the API Gateway - should to be short and descriptive
  opa_master_api_resource = "opa-master"
  opa_master_api_method   = "ANY"

  opa_master_lambda_function_name = "${var.env_prefix}-${var.project}-${local.opa_master_api_resource}"
  opa_master_lambda_description   = "OPA Master Lambda for loading/saving client configurations"

  # main entry point for the lambda function - needs to fit the pattern [python_script.handler_method]
  # otherwise lambda will throw an error that it's unable to find the main entry point
  opa_master_lambda_handler = "opa.api.opa_master.lambda_handler"

  opa_master_lambda_security_group_ids = ["${aws_security_group.default.id}"]
}

# Module creating the api method and lambda for load/save access to OPA Master database
module "api_method_opa_master" {
  source = "../api-method/"

  api_name                     = "${aws_api_gateway_rest_api.api.name}"
  api_gateway_id               = "${aws_api_gateway_rest_api.api.id}"
  api_gateway_root_resource_id = "${aws_api_gateway_rest_api.api.root_resource_id}"
  api_resource                 = "${local.opa_master_api_resource}"
  api_method                   = "${local.opa_master_api_method}"
  api_stage_name               = "${var.stage_name}"

  lambda_description   = "${local.opa_master_lambda_description}"
  lambda_function_name = "${local.opa_master_lambda_function_name}"
  lambda_s3_bucket     = "${var.opa_api_source_code_s3_bucket}"
  lambda_s3_key        = "${var.opa_api_source_code_s3_key}"
  lambda_handler       = "${local.opa_master_lambda_handler}"

  lambda_subnet_ids         = ["${var.private_subnet_ids}"]
  lambda_security_group_ids = ["${local.opa_master_lambda_security_group_ids}"]
  lambda_environment_vars   = "${local.environment_vars}"

  env_prefix  = "${var.env_prefix}"
  global_tags = "${var.global_tags}"
}
