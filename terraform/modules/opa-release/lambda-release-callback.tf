/*
    This tf file is to create opa_release_callback lambda using api/exec/release_callback.py
    and set its Execution role
*/

# defining opa-release-callback lambda function
module "opa-release-callback-lambda" {
  source        = "git::https://github.optum.com/CommercialCloud-EAC/aws_lambda.git?ref=v2.0.0"
  function_name = "${var.env_prefix}-opa-release-callback"
  s3_bucket     = "${var.opa_api_source_code_s3_bucket}"
  s3_key        = "${var.opa_api_source_code_s3_key}"
  handler       = "opa.exec.release_callback.lambda_handler"
  trigger_count = 1

  triggers = [{
    trigger_id         = "${var.env_prefix}-opa-release-sns-topic"
    trigger_principal  = "sns.amazonaws.com"
    trigger_source_arn = "${var.opa_release_sns_topic_arn}"
  }]

  custom_inline_policy_count = 1

  custom_inline_policies = [
    {
      custom_inline_name   = "SSMAndStepFunctionAccessPolicy"
      custom_inline_policy = "${data.aws_iam_policy_document.opa-release-callback-inline-policy-document.json}"
    },
  ]

  environment_vars = {
    ENV_PREFIX = "${var.env_prefix}"
  }

  global_tags = "${var.global_tags}"
}

# create opa_release_callback lambda inline policy: SSM and step function access
data "aws_iam_policy_document" "opa-release-callback-inline-policy-document" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:DeleteParameter", "ssm:GetParameter"]
    resources = ["arn:aws:ssm:${local.aws_region}:${local.account_id}:parameter/${var.env_prefix}/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["states:SendTaskSuccess", "states:SendTaskFailure"]
    resources = ["*"]
  }
}

resource "aws_sns_topic_subscription" "opa-release-sns-subscription-callback-lambda" {
  topic_arn = "${var.opa_release_sns_topic_arn}"
  protocol  = "lambda"
  endpoint  = "${module.opa-release-callback-lambda.arn}"
}
