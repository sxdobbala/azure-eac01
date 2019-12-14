locals {
  # Name of the resource on the API Gateway - should be short and descriptive
  opa_tf_runner_api_resource = "opa-tf-runner"
  opa_tf_runner_api_method   = "POST"

  opa_tf_runner_lambda_function_name = "${var.env_prefix}-${var.project}-${local.opa_tf_runner_api_resource}"
  opa_tf_runner_lambda_description   = "OPA Lambda for executing terraform in AWS"

  # main entry point for the lambda function - needs to fit the pattern [python_script.handler_method]
  # otherwise lambda will throw an error that it's unable to find the main entry point
  opa_tf_runner_lambda_handler = "opa.api.opa_tf_runner.lambda_handler"

  # TODO: terraform will need access to most things to be able to create/destroy resources
  # TODO: but we can still attempt to restrict to specific actions or source bucket/key combos
  opa_tf_runner_lambda_custom_managed_policies = ["arn:aws:iam::aws:policy/AdministratorAccess"]

  opa_tf_runner_lambda_security_group_ids = ["${aws_security_group.default.id}"]
}

module "api_method_opa_tf_runner" {
  source = "../api-method/"

  api_name                     = "${aws_api_gateway_rest_api.api.name}"
  api_gateway_id               = "${aws_api_gateway_rest_api.api.id}"
  api_gateway_root_resource_id = "${aws_api_gateway_rest_api.api.root_resource_id}"
  api_resource                 = "${local.opa_tf_runner_api_resource}"
  api_method                   = "${local.opa_tf_runner_api_method}"
  api_stage_name               = "${var.stage_name}"

  lambda_description   = "${local.opa_tf_runner_lambda_description}"
  lambda_function_name = "${local.opa_tf_runner_lambda_function_name}"
  lambda_s3_bucket     = "${var.opa_api_source_code_s3_bucket}"
  lambda_s3_key        = "${var.opa_api_source_code_s3_key}"
  lambda_handler       = "${local.opa_tf_runner_lambda_handler}"
  lambda_memory_size   = "1024"

  lambda_subnet_ids              = ["${var.private_subnet_ids}"]
  lambda_security_group_ids      = ["${local.opa_tf_runner_lambda_security_group_ids}"]
  lambda_custom_managed_policies = "${local.opa_tf_runner_lambda_custom_managed_policies}"
  lambda_environment_vars        = "${local.environment_vars}"

  env_prefix  = "${var.env_prefix}"
  global_tags = "${var.global_tags}"
}
