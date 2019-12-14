module "mstr-elb-cleanup-lambda" {
  source = "git::https://github.optum.com/CommercialCloud-EAC/aws_lambda.git?ref=v2.0.0"

  function_name = "${var.env_prefix}-mstr-elb-cleanup"
  description   = "OPA Lambda to remove redundant ELB instances set up by MSTR stack"
  handler       = "opa.exec.mstr_elb_cleanup.lambda_handler"
  s3_bucket     = "${var.opa_api_source_code_s3_bucket}"
  s3_key        = "${var.opa_api_source_code_s3_key}"

  environment_vars = {
    ENV_PREFIX = "${var.env_prefix}"
  }

  custom_inline_policy_count = 1

  custom_inline_policies = [
    {
      custom_inline_name   = "MstrElbCleanupLambdaAccessPolicy"
      custom_inline_policy = "${data.aws_iam_policy_document.mstr-elb-cleanup-lambda-policy-doc.json}"
    },
  ]

  global_tags = "${var.global_tags}"
}

data "aws_iam_policy_document" "mstr-elb-cleanup-lambda-policy-doc" {
  statement {
    effect = "Allow"

    actions = [
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeListeners",
    ]

    resources = ["*"]
  }

  statement {
    effect  = "Allow"
    actions = ["elasticloadbalancing:DeleteLoadBalancer"]

    resources = [
      "arn:aws:elasticloadbalancing:${local.aws_region}:${local.account_id}:loadbalancer/env-*-elb",
      "arn:aws:elasticloadbalancing:${local.aws_region}:${local.account_id}:loadbalancer/app/env-*-appelb/*",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["elasticloadbalancing:DeleteListener"]
    resources = ["arn:aws:elasticloadbalancing:${local.aws_region}:${local.account_id}:listener/app/env-*-appelb/*"]
  }
}
