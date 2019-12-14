data "aws_caller_identity" "current_identity" {}

data "aws_region" "current_region" {}

locals {
  lambda_custom_managed_policies = "${compact(concat(list(
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"), var.lambda_custom_managed_policies))}"

  api_account_id = "${data.aws_caller_identity.current_identity.account_id}"
  api_region     = "${data.aws_region.current_region.name}"
}

# API Gateway

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = "${var.api_gateway_id}"
  stage_name  = "${var.api_stage_name}"
  depends_on  = ["aws_api_gateway_integration.request_method_integration", "aws_api_gateway_integration_response.response_method_integration"]
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${var.api_gateway_id}"
  parent_id   = "${var.api_gateway_root_resource_id}"
  path_part   = "${var.api_resource}"
}

resource "aws_api_gateway_method" "request_method" {
  rest_api_id   = "${var.api_gateway_id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "${var.api_method}"
  authorization = "AWS_IAM"
}

resource "aws_api_gateway_integration" "request_method_integration" {
  rest_api_id = "${var.api_gateway_id}"
  resource_id = "${aws_api_gateway_resource.proxy.id}"
  http_method = "${aws_api_gateway_method.request_method.http_method}"
  type        = "AWS_PROXY"
  uri         = "arn:aws:apigateway:${local.api_region}:lambda:path/2015-03-31/functions/${module.api_lambda.arn}/invocations"

  # AWS lambdas can only be invoked with the POST method
  integration_http_method = "POST"
}

# lambda => GET response
resource "aws_api_gateway_method_response" "response_method" {
  rest_api_id = "${var.api_gateway_id}"
  resource_id = "${aws_api_gateway_resource.proxy.id}"
  http_method = "${aws_api_gateway_integration.request_method_integration.http_method}"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "response_method_integration" {
  rest_api_id = "${var.api_gateway_id}"
  resource_id = "${aws_api_gateway_resource.proxy.id}"
  http_method = "${aws_api_gateway_method_response.response_method.http_method}"
  status_code = "${aws_api_gateway_method_response.response_method.status_code}"

  response_templates = {
    "application/json" = ""
  }
}

# There is a nasty bug in API Gateway which resets Lambda permissions.
# If you get an error "Execution failed due to configuration error: Invalid permissions on Lambda function"
# you can fix the error by going to API Gateway and re-selecting the lambda function in the Integration Request
# See https://forums.aws.amazon.com/thread.jspa?threadID=217254&tstart=0
resource "aws_lambda_permission" "allow_api_gateway" {
  function_name = "${module.api_lambda.arn}"
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"

  # invocations break if you get source_arn from ${aws_api_gateway_deployment.deployment.execution_arn}
  # it's likely that AWS does not like the stage name to be in the arn
  # so we're constructing the source_arn from scratch.
  # TODO: It's possible the second star needs to be method (GET/POST/etc) if we're not using the lambda for ANY method
  source_arn = "arn:aws:execute-api:${local.api_region}:${local.api_account_id}:${var.api_gateway_id}/*/*/${var.api_resource}"

  depends_on = ["aws_api_gateway_resource.proxy"]
}

# Lambda Function

# Create a SNS topic for lambda so we can send lambda failures for debugging
resource "aws_sns_topic" "api_dlq_sns" {
  name = "${var.api_name}-sns-topic"
}

module "api_lambda" {
  source = "git::https://github.optum.com/oaccoe/aws_lambda.git"

  function_name = "${var.lambda_function_name}"
  description   = "${var.lambda_description}"
  s3_bucket     = "${var.lambda_s3_bucket}"
  s3_key        = "${var.lambda_s3_key}"
  runtime       = "${var.lambda_runtime}"
  handler       = "${var.lambda_handler}"
  memory_size   = "${var.lambda_memory_size}"

  subnet_ids         = ["${var.lambda_subnet_ids}"]
  security_group_ids = ["${var.lambda_security_group_ids}"]

  environment_vars = "${var.lambda_environment_vars}"

  # NOTE: we don't use the aws_lambda module triggers here since our aws_lambda_permission
  # has an external dependency on the api gateway integrations

  custom_managed_policies    = ["${local.lambda_custom_managed_policies}"]
  custom_inline_policy_count = "${var.lambda_custom_inline_policy_count}"
  custom_inline_policies     = ["${var.lambda_custom_inline_policies}"]
  # lambda execution failures will be sent to this SNS topic
  dead_letter_config = {
    target_arn = "${aws_sns_topic.api_dlq_sns.arn}"
  }
  attach_dead_letter_config = true
  is_local_archive          = "false"
  global_tags               = "${var.global_tags}"
}
