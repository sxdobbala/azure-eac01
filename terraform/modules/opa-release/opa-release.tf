/*
    This module is used to create step function(sfn) to implement opa-release.
    
    The opa-release-sns-topic(defined in sns_topic.tf) will be used here to pass information from lambdas to callback lambda(defined in opa_release_callback.tf).
    
    The sfn state manchine definition is using /definition/sfn_definition.json.

    This tf file is to create sfn state machine and role.
*/

data "template_file" "opa-release-sfn-definition" {
  template = "${file("${path.module}/definitions/opa-release.json")}"

  vars {
    MSTR_POSTINSTALL_LAMBDA_ARN = "${var.mstr_postinstall_lambda_arn}"
    SYNC_RELEASE_LAMBDA_ARN     = "${module.opa-release-sync-release-lambda.arn}"
    DEPLOY_OPA_LAMBDA_ARN       = "${var.deploy_opa_lambda_arn}"
    DEPLOY_MSTR_LAMBDA_ARN      = "${var.deploy_mstr_lambda_arn}"
    DEPLOY_RW_SCHEMA_LAMBDA_ARN = "${var.opa_deploy_rw_schema_lambda_arn}"
  }
}

resource "aws_sfn_state_machine" "opa-release-sfn" {
  name       = "${var.env_prefix}-opa-release-sfn"
  role_arn   = "${aws_iam_role.opa-release-sfn-role.arn}"
  definition = "${data.template_file.opa-release-sfn-definition.rendered}"
  tags       = "${var.global_tags}"
}

data "aws_iam_policy_document" "opa-release-sfn-role-policy-document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.${local.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "opa-release-sfn-role" {
  name               = "${var.env_prefix}-opa-release-sfn-role"
  assume_role_policy = "${data.aws_iam_policy_document.opa-release-sfn-role-policy-document.json}"
}

data "aws_iam_policy_document" "opa-release-sfn-resource-policy-document" {
  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]

    resources = [
      "${var.mstr_postinstall_lambda_arn}",
      "${module.opa-release-sync-release-lambda.arn}",
      "${var.deploy_opa_lambda_arn}",
      "${var.deploy_mstr_lambda_arn}",
      "${var.opa_master_lambda_arn}",
      "${var.opa_deploy_rw_schema_lambda_arn}",
    ]
  }
}

resource "aws_iam_policy" "opa-release-sfn-resource-policy" {
  name        = "${var.env_prefix}-opa-release-sfn-resource-policy"
  description = "Resources accessible to the opa-release workflow"
  policy      = "${data.aws_iam_policy_document.opa-release-sfn-resource-policy-document.json}"
}

resource "aws_iam_role_policy_attachment" "opa-release-sfn-resource-policy-attachment" {
  role       = "${aws_iam_role.opa-release-sfn-role.name}"
  policy_arn = "${aws_iam_policy.opa-release-sfn-resource-policy.arn}"
}
