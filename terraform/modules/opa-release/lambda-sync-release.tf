/*
    This tf file is to create sync_release lambda using /lambda/sync_release.py
    and set its Execution role
*/

# defining sync-release lambda function
module "opa-release-sync-release-lambda" {
  source                     = "git::https://github.optum.com/CommercialCloud-EAC/aws_lambda.git?ref=v2.0.0"
  function_name              = "${var.env_prefix}-sync-release"
  s3_bucket                  = "${var.opa_api_source_code_s3_bucket}"
  s3_key                     = "${var.opa_api_source_code_s3_key}"
  handler                    = "opa.exec.sync_release.lambda_handler"
  trigger_count              = 0
  custom_inline_policy_count = 1

  custom_inline_policies = [
    {
      custom_inline_name   = "SSMAccessAndPassRolePolicy"
      custom_inline_policy = "${data.aws_iam_policy_document.opa-release-sync-release-inline-policy-document.json}"
    },
  ]

  environment_vars = {
    SNS_TOPIC_ARN         = "${var.opa_release_sns_topic_arn}"
    SNS_ROLE_ARN          = "${var.opa_release_sns_role_arn}"
    ENV_PREFIX            = "${var.env_prefix}"
    OPA_RELEASE_S3_BUCKET = "${var.opa_release_s3_bucket}"
    OPA_RELEASE_S3_PREFIX = "${var.opa_release_s3_prefix}"
    ARTIFACTS_S3_BUCKET   = "${var.artifacts_s3_bucket}"
  }

  global_tags = "${var.global_tags}"
}

# create sync-release lambda inline policy: SSM access and iam:PassRole
# iam:PassRole policy allows a caller (Lambda in our case) to pass the role created (sns-topic-role) in API calls to other AWS services, like SSM
data "aws_iam_policy_document" "opa-release-sync-release-inline-policy-document" {
  statement {
    effect  = "Allow"
    actions = ["ssm:SendCommand"]

    # TODO: Restrict to EC2 instances (preferably just MSTR ones) in a given logical environment
    resources = ["arn:aws:ec2:${local.aws_region}:${local.account_id}:instance/*", "arn:aws:ssm:${local.aws_region}:*:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ssm:PutParameter"]
    resources = ["arn:aws:ssm:${local.aws_region}:${local.account_id}:parameter/${var.env_prefix}/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["${var.opa_release_sns_role_arn}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["cloudformation:DescribeStacks"]
    resources = ["arn:aws:cloudformation:${local.aws_region}:${local.account_id}:stack/env-*/*"]
  }
}

# upload sync.sh to s3 bucket
resource "aws_s3_bucket_object" "opa-release-sync-script-object" {
  bucket = "${var.artifacts_s3_bucket}"
  key    = "${var.env_prefix}/opa-release/sync.sh"
  source = "${path.module}/scripts/sync.sh"
  tags   = "${var.global_tags}"
  etag   = "${md5(file("${path.module}/scripts/sync.sh"))}"
}
