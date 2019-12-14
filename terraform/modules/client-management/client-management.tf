data "template_file" "client-management-sfn-definition" {
  template = "${file("${path.module}/definitions/client-management.json")}"

  vars {
    ENV_PREFIX                      = "${var.env_prefix}"
    MSTR_BACKUP_SFN_ARN             = "${var.mstr_backup_sfn_arn}"
    MSTR_ENVIRONMENT_CREATE_SFN_ARN = "${var.mstr_environment_create_sfn_arn}"
    OPA_RELEASE_SFN_ARN             = "${var.opa_release_sfn_arn}"
    CLIENT_ONBOARDING_SFN_ARN       = "${var.client_onboarding_sfn_arn}"
    CLIENT_STACK_ROTATION_SFN_ARN   = "${var.client_stack_rotation_sfn_arn}"
    NOTIFICATION_SNS_TOPIC          = "${var.opa_operations_sns_topic}"
  }
}

resource "aws_sfn_state_machine" "client-management-sfn" {
  name       = "${var.env_prefix}-client-management-sfn"
  role_arn   = "${aws_iam_role.client-management-sfn-role.arn}"
  definition = "${data.template_file.client-management-sfn-definition.rendered}"
  tags       = "${var.global_tags}"
}

data "aws_iam_policy_document" "client-management-sfn-role-document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.${local.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "client-management-sfn-role" {
  name               = "${var.env_prefix}-client-management-sfn-role"
  assume_role_policy = "${data.aws_iam_policy_document.client-management-sfn-role-document.json}"
}

data "aws_iam_policy_document" "client-management-sfn-resource-policy-document" {
  statement {
    effect  = "Allow"
    actions = ["states:*"]

    resources = [
      "*",
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["events:*"]

    resources = [
      "arn:aws:events:${local.aws_region}:${local.account_id}:rule/StepFunctionsGetEventsForStepFunctionsExecutionRule",
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = ["${var.ci_sns_topic}", "${var.opa_operations_sns_topic}"]
  }
}

resource "aws_iam_policy" "client-management-sfn-resource-policy" {
  name        = "${var.env_prefix}-client-management-sfn-resource-policy"
  description = "Resources that the client-management step function can invoke"
  policy      = "${data.aws_iam_policy_document.client-management-sfn-resource-policy-document.json}"
}

resource "aws_iam_role_policy_attachment" "client-management-sfn-resource-policy-attachment" {
  role       = "${aws_iam_role.client-management-sfn-role.name}"
  policy_arn = "${aws_iam_policy.client-management-sfn-resource-policy.arn}"
}
