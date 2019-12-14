locals {
  lambda_custom_managed_policies = "${compact(concat(list(
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"), var.lambda_custom_managed_policies))}"
}

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
  timeout       = "${var.lambda_timeout}"

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
