data "aws_iam_policy_document" "invoke-api-lambdas-policy-doc" {
  statement {
    sid     = "AllowInvokeFunction"
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]

    resources = [
      "${module.api_method_opa_master.arn}",
      "${module.api_method_opa_data_load.arn}",
      "${module.api_method_opa_post_data_load.arn}",
      "${module.api_method_opa_s3_folder_sync.arn}",
      "${module.api_method_opa_command.arn}",
    ]
  }
}

resource "aws_iam_policy" "invoke-api-lambdas-policy" {
  name        = "${var.env_prefix}-AllowDataServiceRoleToInvokeApiLambdas"
  description = "Allows DataLoadService to invoke certain API lambdas"
  policy      = "${data.aws_iam_policy_document.invoke-api-lambdas-policy-doc.json}"
}

resource "aws_iam_role_policy_attachment" "invoke-api-lambdas-policy-attachment" {
  policy_arn = "${aws_iam_policy.invoke-api-lambdas-policy.arn}"
  role       = "${var.data_load_service_role_name}"
}

data "aws_iam_policy_document" "api-sns-publish-policy-doc" {
  statement {
    sid       = "AllowSNSPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = ["arn:aws:sns:${local.aws_region}:${local.account_id}:*"]
  }
}

resource "aws_iam_policy" "api-sns-publish-policy" {
  name        = "${var.env_prefix}-AllowApiLambdasToPublishToSNS"
  description = "Allows certain API lambdas to publish to SNS"
  policy      = "${data.aws_iam_policy_document.api-sns-publish-policy-doc.json}"
}

data "aws_iam_policy_document" "api-ssm-get-parameter-policy-doc" {
  statement {
    sid       = "AllowSsmGetParameterAccess"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${local.aws_region}:${local.account_id}:parameter/*"]
  }
}

resource "aws_iam_policy" "api-ssm-get-parameter-policy" {
  name        = "${var.env_prefix}-AllowApiLambdasToSsmGetParameter"
  description = "Allows certain API lambdas to SSM get parameter"
  policy      = "${data.aws_iam_policy_document.api-ssm-get-parameter-policy-doc.json}"
}

data "aws_iam_policy_document" "api-ssm-put-parameter-policy-doc" {
  statement {
    sid       = "AllowSsmPutParameterAccess"
    effect    = "Allow"
    actions   = ["ssm:PutParameter"]
    resources = ["arn:aws:ssm:${local.aws_region}:${local.account_id}:parameter/*"]
  }
}

resource "aws_iam_policy" "api-ssm-put-parameter-policy" {
  name        = "${var.env_prefix}-AllowApiLambdasToSsmPutParameter"
  description = "Allows certain API lambdas to SSM put parameter"
  policy      = "${data.aws_iam_policy_document.api-ssm-put-parameter-policy-doc.json}"
}

data "aws_iam_policy_document" "api-ssm-get-command-invocation-policy-doc" {
  statement {
    sid       = "AllowSsmGetCommandInvocationAccess"
    effect    = "Allow"
    actions   = ["ssm:GetCommandInvocation"]
    resources = ["arn:aws:ssm:${local.aws_region}:${local.account_id}:*"]
  }
}

resource "aws_iam_policy" "api-ssm-get-command-invocation-policy" {
  name        = "${var.env_prefix}-AllowApiLambdasToSsmGetCommandInvocation"
  description = "Allows certain API lambdas to SSM get command invocation"
  policy      = "${data.aws_iam_policy_document.api-ssm-get-command-invocation-policy-doc.json}"
}

data "aws_iam_policy_document" "api-ssm-send-command-policy-doc" {
  statement {
    sid       = "AllowSsmSendCommandRunShellAccess"
    effect    = "Allow"
    actions   = ["ssm:SendCommand"]
    resources = ["arn:aws:ssm:${local.aws_region}::document/AWS-RunShellScript"]
  }

  statement {
    sid     = "AllowSsmSendCommandEc2InstanceAccess"
    effect  = "Allow"
    actions = ["ssm:SendCommand"]

    resources = ["arn:aws:ec2:${local.aws_region}:${local.account_id}:instance/*"]
  }
}

resource "aws_iam_policy" "api-ssm-send-command-policy" {
  name        = "${var.env_prefix}-AllowApiLambdasToSsmSendCommand"
  description = "Allows certain API lambdas to SSM send command"
  policy      = "${data.aws_iam_policy_document.api-ssm-send-command-policy-doc.json}"
}

data "aws_iam_policy_document" "api-cloudwatch-logs-policy-doc" {
  statement {
    sid       = "AllowLogsDescribeLogStreams"
    effect    = "Allow"
    actions   = ["logs:DescribeLogStreams"]
    resources = ["*"]
  }

  statement {
    sid       = "AllowLogsGetLogEvents"
    effect    = "Allow"
    actions   = ["logs:GetLogEvents"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "api-cloudwatch-logs-policy" {
  name        = "${var.env_prefix}-AllowApiLambdasToReadCloudWatchLogs"
  description = "Allows certain API lambdas to read CloudWatch logs"
  policy      = "${data.aws_iam_policy_document.api-cloudwatch-logs-policy-doc.json}"
}

data "aws_iam_policy_document" "api-step-function-policy-doc" {
  statement {
    sid       = "AllowStatesDescribeAndStartExecution"
    effect    = "Allow"
    actions   = ["states:DescribeExecution", "states:StartExecution"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "api-step-function-policy" {
  name        = "${var.env_prefix}-AllowApiLambdasToInvokeStepFunctions"
  description = "Allows certain API lambdas to invoke step function methods"
  policy      = "${data.aws_iam_policy_document.api-step-function-policy-doc.json}"
}

data "aws_iam_policy_document" "api-cloudformation-redshift-policy-doc" {
  statement {
    sid       = "AllowCloudFormationRedshiftDescribe"
    effect    = "Allow"
    actions   = ["cloudformation:Describe*", "redshift:Describe*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "api-cloudformation-redshift-policy" {
  name        = "${var.env_prefix}-AllowCloudFormationRedshiftDescribe"
  description = "Allows certain API lambdas to invoke cloud formation and redshift describe methods"
  policy      = "${data.aws_iam_policy_document.api-cloudformation-redshift-policy-doc.json}"
}

data "aws_iam_policy_document" "api-ec2-policy-doc" {
  statement {
    sid    = "AllowEC2Methods"
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:ModifyInstanceAttribute",
      "ec2:RebootInstances",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "api-ec2-policy" {
  name        = "${var.env_prefix}-AllowEC2Methods"
  description = "Allows certain API lambdas to invoke EC2 methods"
  policy      = "${data.aws_iam_policy_document.api-ec2-policy-doc.json}"
}

# reusable sets of policies
locals {
  policy_for_command_only = [
    "${aws_iam_policy.api-sns-publish-policy.arn}",
    "${aws_iam_policy.api-ssm-get-command-invocation-policy.arn}",
    "${aws_iam_policy.api-ssm-send-command-policy.arn}",
  ]

  policy_for_command_only_count = 3

  policy_for_ssm_with_params_cloudwatch = [
    "${aws_iam_policy.api-sns-publish-policy.arn}",
    "${aws_iam_policy.api-ssm-get-parameter-policy.arn}",
    "${aws_iam_policy.api-ssm-get-command-invocation-policy.arn}",
    "${aws_iam_policy.api-ssm-send-command-policy.arn}",
    "${aws_iam_policy.api-cloudwatch-logs-policy.arn}",
  ]

  policy_for_ssm_with_params_cloudwatch_count = 5

  policy_for_ssm_with_set_params_cloudwatch       = "${concat(local.policy_for_ssm_with_params_cloudwatch, list(aws_iam_policy.api-ssm-put-parameter-policy.arn))}"
  policy_for_ssm_with_set_params_cloudwatch_count = 6
}

# opa-mstr-stack

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-mstr-stack" {
  policy_arn = "${aws_iam_policy.api-sns-publish-policy.arn}"
  role       = "${module.api_method_opa_mstr_stack.role_name}"
}

# opa-client-onboarding

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-client-onboarding" {
  count      = "${local.policy_for_ssm_with_set_params_cloudwatch_count}"
  policy_arn = "${local.policy_for_ssm_with_set_params_cloudwatch[count.index]}"
  role       = "${module.api_method_opa_client_onboarding.role_name}"
}

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-client-onboarding-cf-redshift" {
  policy_arn = "${aws_iam_policy.api-cloudformation-redshift-policy.arn}"
  role       = "${module.api_method_opa_client_onboarding.role_name}"
}

# opa-client-redshift-security

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-client-redshift-security" {
  count      = "${local.policy_for_ssm_with_set_params_cloudwatch_count}"
  policy_arn = "${local.policy_for_ssm_with_set_params_cloudwatch[count.index]}"
  role       = "${module.api_method_opa_client_redshift_security.role_name}"
}

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-client-redshift-security-cf" {
  policy_arn = "${aws_iam_policy.api-cloudformation-redshift-policy.arn}"
  role       = "${module.api_method_opa_client_redshift_security.role_name}"
}

# opa-command

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-command" {
  count      = "${local.policy_for_command_only_count}"
  policy_arn = "${local.policy_for_command_only[count.index]}"
  role       = "${module.api_method_opa_command.role_name}"
}

# opa-data-load

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-data-load" {
  count      = "${local.policy_for_ssm_with_params_cloudwatch_count}"
  policy_arn = "${local.policy_for_ssm_with_params_cloudwatch[count.index]}"
  role       = "${module.api_method_opa_data_load.role_name}"
}

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-data-load-cf" {
  policy_arn = "${aws_iam_policy.api-cloudformation-redshift-policy.arn}"
  role       = "${module.api_method_opa_data_load.role_name}"
}

# opa-master-schema

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-master-schema" {
  policy_arn = "${aws_iam_policy.api-sns-publish-policy.arn}"
  role       = "${module.api_method_opa_master_schema.role_name}"
}

resource "aws_iam_role_policy_attachment" "api-ssm-get-parameter-policy-attachment-opa-master-schema" {
  policy_arn = "${aws_iam_policy.api-ssm-get-parameter-policy.arn}"
  role       = "${module.api_method_opa_master_schema.role_name}"
}

# opa-master

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-master" {
  policy_arn = "${aws_iam_policy.api-sns-publish-policy.arn}"
  role       = "${module.api_method_opa_master.role_name}"
}

resource "aws_iam_role_policy_attachment" "api-ssm-get-parameter-policy-attachment-opa-master" {
  policy_arn = "${aws_iam_policy.api-ssm-get-parameter-policy.arn}"
  role       = "${module.api_method_opa_master.role_name}"
}

# opa-mstr-backup

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-mstr-backup" {
  count      = "${local.policy_for_ssm_with_set_params_cloudwatch_count}"
  policy_arn = "${local.policy_for_ssm_with_set_params_cloudwatch[count.index]}"
  role       = "${module.api_method_opa_mstr_backup.role_name}"
}

# opa-mstr-metadata

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-mstr-metadata" {
  count      = "${local.policy_for_ssm_with_params_cloudwatch_count}"
  policy_arn = "${local.policy_for_ssm_with_params_cloudwatch[count.index]}"
  role       = "${module.api_method_opa_mstr_metadata.role_name}"
}

# opa-mstr-migration

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-mstr-migration" {
  count      = "${local.policy_for_ssm_with_set_params_cloudwatch_count}"
  policy_arn = "${local.policy_for_ssm_with_set_params_cloudwatch[count.index]}"
  role       = "${module.api_method_opa_mstr_migration.role_name}"
}

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-mstr-migration-cf" {
  policy_arn = "${aws_iam_policy.api-cloudformation-redshift-policy.arn}"
  role       = "${module.api_method_opa_mstr_migration.role_name}"
}

# opa-post-data-load

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-post-data-load" {
  count      = "${local.policy_for_ssm_with_params_cloudwatch_count}"
  policy_arn = "${local.policy_for_ssm_with_params_cloudwatch[count.index]}"
  role       = "${module.api_method_opa_post_data_load.role_name}"
}

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-post-data-load-cf-redshift" {
  policy_arn = "${aws_iam_policy.api-cloudformation-redshift-policy.arn}"
  role       = "${module.api_method_opa_post_data_load.role_name}"
}

# opa-s3-folder-sync

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-s3-folder-sync" {
  count      = "${local.policy_for_command_only_count}"
  policy_arn = "${local.policy_for_command_only[count.index]}"
  role       = "${module.api_method_opa_s3_folder_sync.role_name}"
}

# opa-smoke-test

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-smoke-test" {
  policy_arn = "${aws_iam_policy.api-sns-publish-policy.arn}"
  role       = "${module.api_method_opa_smoke_test.role_name}"
}

# opa-tf-runner

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-tf-runner" {
  policy_arn = "${aws_iam_policy.api-sns-publish-policy.arn}"
  role       = "${module.api_method_opa_tf_runner.role_name}"
}

# deploy-rw-schema

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-deploy-rw-schema" {
  count      = "${local.policy_for_ssm_with_set_params_cloudwatch_count}"
  policy_arn = "${local.policy_for_ssm_with_set_params_cloudwatch[count.index]}"
  role       = "${module.api_method_opa_deploy_rw_schema.role_name}"
}

# opa-client-env-move

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-client-env-move" {
  count      = "${local.policy_for_ssm_with_set_params_cloudwatch_count}"
  policy_arn = "${local.policy_for_ssm_with_set_params_cloudwatch[count.index]}"
  role       = "${module.api_method_opa_client_env_move.role_name}"
}

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-client-env-move-cf" {
  policy_arn = "${aws_iam_policy.api-cloudformation-redshift-policy.arn}"
  role       = "${module.api_method_opa_client_env_move.role_name}"
}

# opa-timezone-change

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-timezone-change" {
  count      = "${local.policy_for_command_only_count}"
  policy_arn = "${local.policy_for_command_only[count.index]}"
  role       = "${module.api_method_opa_timezone_change.role_name}"
}

resource "aws_iam_role_policy_attachment" "policy-attachment-opa-timezone-change-ec2" {
  policy_arn = "${aws_iam_policy.api-ec2-policy.arn}"
  role       = "${module.api_method_opa_timezone_change.role_name}"
}
