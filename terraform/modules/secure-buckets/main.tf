locals {
  function_name    = "secure-buckets"
  config_rule_name = "S3_BUCKET_SSL_REQUESTS_ONLY"
  config_rule_arn  = "${var.is_prod == "true" ? "arn:aws:config:us-east-1:029620356096:config-rule/config-rule-suat1t" : "arn:aws:config:us-east-1:760182235631:config-rule/config-rule-he514r"}"
}

module "secure-buckets-lambda" {
  source        = "git::https://github.optum.com/CommercialCloud-EAC/aws_lambda.git?ref=v2.0.0"
  function_name = "${local.function_name}"
  description   = "Ensures all S3 buckets in the account require SSL"
  s3_bucket     = "${var.opa_api_source_code_s3_bucket}"
  s3_key        = "${var.opa_api_source_code_s3_key}"
  handler       = "opa.exec.secure_buckets.lambda_handler"

  trigger_count = 1

  triggers = [{
    trigger_id         = "AllowExecuteFromSNS"
    trigger_principal  = "sns.amazonaws.com"
    trigger_source_arn = "${aws_sns_topic.secure-buckets-topic.arn}"
  }]

  custom_inline_policy_count = 1

  custom_inline_policies = [
    {
      custom_inline_name   = "ReadAndWriteS3BucketPolicies"
      custom_inline_policy = "${data.aws_iam_policy_document.secure-buckets-lambda-policy.json}"
    },
  ]

  global_tags = "${var.global_tags}"
}

data "aws_iam_policy_document" "secure-buckets-lambda-policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetBucketPolicy", "s3:PutBucketPolicy"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["config:GetComplianceDetailsByConfigRule"]
    resources = ["${local.config_rule_arn}"]
  }
}

resource "aws_sns_topic" "secure-buckets-topic" {
  name = "${local.config_rule_name}-remediation-sns-topic"
}

resource "aws_sns_topic_subscription" "secure-buckets-topic-subscription" {
  topic_arn = "${aws_sns_topic.secure-buckets-topic.arn}"
  protocol  = "lambda"
  endpoint  = "${module.secure-buckets-lambda.arn}"
}

module "secure-buckets-schedule-run" {
  source = "../schedule-lambda-run"

  env_prefix          = "${var.env_prefix}"
  rule_name           = "schedule-run-${local.function_name}"
  lambda_name         = "${local.function_name}"
  lambda_arn          = "${module.secure-buckets-lambda.arn}"
  schedule_expression = "rate(1 hour)"
  global_tags         = "${var.global_tags}"
}
