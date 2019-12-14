locals {
  # Name of the resource on the API Gateway - should to be short and descriptive
  opa_mstr_migration_api_resource = "opa-mstr-migration"
  opa_mstr_migration_api_method   = "ANY"

  opa_mstr_migration_lambda_function_name = "${var.env_prefix}-${var.project}-${local.opa_mstr_migration_api_resource}"
  opa_mstr_migration_lambda_description   = "OPA Lambda for management of MSTR migrations"

  # main entry point for the lambda function - needs to fit the pattern [python_script.handler_method]
  # otherwise lambda will throw an error that it's unable to find the main entry point
  opa_mstr_migration_lambda_handler = "opa.api.opa_mstr_migration.lambda_handler"

  opa_mstr_migration_lambda_security_group_ids = ["${aws_security_group.default.id}"]
}

data "aws_iam_policy_document" "api-method-opa-mstr-migration-policy-doc" {
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["${local.environment_vars["OPA_RELEASE_SNS_ROLE_ARN"]}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.artifacts_s3_id}/e2e-releases/*"]
  }
}

# Module creating the api method and lambda to execute MSTR migration
module "api_method_opa_mstr_migration" {
  source = "../api-method/"

  api_name                     = "${aws_api_gateway_rest_api.api.name}"
  api_gateway_id               = "${aws_api_gateway_rest_api.api.id}"
  api_gateway_root_resource_id = "${aws_api_gateway_rest_api.api.root_resource_id}"
  api_resource                 = "${local.opa_mstr_migration_api_resource}"
  api_method                   = "${local.opa_mstr_migration_api_method}"
  api_stage_name               = "${var.stage_name}"

  lambda_description   = "${local.opa_mstr_migration_lambda_description}"
  lambda_function_name = "${local.opa_mstr_migration_lambda_function_name}"
  lambda_s3_bucket     = "${var.opa_api_source_code_s3_bucket}"
  lambda_s3_key        = "${var.opa_api_source_code_s3_key}"
  lambda_handler       = "${local.opa_mstr_migration_lambda_handler}"

  lambda_subnet_ids         = ["${var.private_subnet_ids}"]
  lambda_security_group_ids = ["${local.opa_mstr_migration_lambda_security_group_ids}"]
  lambda_environment_vars   = "${local.environment_vars}"

  lambda_custom_inline_policy_count = 1

  lambda_custom_inline_policies = [
    {
      custom_inline_name   = "${local.opa_mstr_migration_lambda_function_name}-IAM-Policy"
      custom_inline_policy = "${data.aws_iam_policy_document.api-method-opa-mstr-migration-policy-doc.json}"
    },
  ]

  env_prefix  = "${var.env_prefix}"
  global_tags = "${var.global_tags}"
}
