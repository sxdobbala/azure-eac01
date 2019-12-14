module "mstr-stack-status-lambda" {
  source        = "git::https://github.optum.com/CommercialCloud-EAC/aws_lambda.git?ref=v2.0.0"
  description   = "OPA Lambda for getting the status of a cloud formation stack"
  function_name = "${var.env_prefix}-cloudformation-stack-status"
  s3_bucket     = "${var.opa_api_source_code_s3_bucket}"
  s3_key        = "${var.opa_api_source_code_s3_key}"
  handler       = "opa.exec.stack_status.lambda_handler"

  custom_inline_policy_count = 1

  custom_inline_policies = [
    {
      custom_inline_name   = "CFStackStatusAccessPolicy"
      custom_inline_policy = "${data.aws_iam_policy_document.mstr-stack-status-inline-policy-document.json}"
    },
  ]

  global_tags = "${var.global_tags}"
}

data "aws_iam_policy_document" "mstr-stack-status-inline-policy-document" {
  statement {
    effect    = "Allow"
    actions   = ["cloudformation:ListStacks"]
    resources = ["*"]
  }
}
