#############################################################################################
# Step function to create a MSTR environment - main entry point for workflow which combines
# creation of MSTR backup, MSTR stack, and other resources.
#############################################################################################

data "template_file" "mstr-environment-create-sfn-definition" {
  template = "${file("${path.module}/definitions/mstr-environment-create.json")}"

  vars {
    # state machines
    MSTR_STACK_CREATE_SFN_ARN = "${aws_sfn_state_machine.mstr-stack-create-sfn.id}"

    # tf-runner lambda
    TF_RUNNER_LAMBDA_ARN      = "${var.opa_tf_runner_lambda_arn}"
    TF_SOURCE_BUCKET          = "${var.artifacts_s3_bucket}"
    TF_SOURCE_KEY             = "${var.opa_mstr_aws_archive_s3_key}"
    ENV_PREFIX                = "${var.env_prefix}"
    OPA_RELEASE_SNS_TOPIC_ARN = "${var.opa_release_sns_topic_arn}"
    VPC_ID                    = "${var.vpc_id}"
  }
}

resource "aws_sfn_state_machine" "mstr-environment-create-sfn" {
  name       = "${var.env_prefix}-mstr-environment-create-sfn"
  role_arn   = "${aws_iam_role.mstr-environment-create-sfn-role.arn}"
  definition = "${data.template_file.mstr-environment-create-sfn-definition.rendered}"
  tags       = "${var.global_tags}"
}

data "aws_iam_policy_document" "mstr-environment-create-sfn-role-document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.${local.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "mstr-environment-create-sfn-role" {
  name               = "${var.env_prefix}-mstr-environment-create-sfn-role"
  assume_role_policy = "${data.aws_iam_policy_document.mstr-environment-create-sfn-role-document.json}"
}

data "aws_iam_policy_document" "mstr-environment-create-sfn-resource-policy-document" {
  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]

    resources = [
      "${var.opa_tf_runner_lambda_arn}",
    ]
  }

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
}

resource "aws_iam_policy" "mstr-environment-create-sfn-resource-policy" {
  name        = "${var.env_prefix}-mstr-environment-create-sfn-resource"
  description = "Resources that the mstr-environment step function can invoke"
  policy      = "${data.aws_iam_policy_document.mstr-environment-create-sfn-resource-policy-document.json}"
}

resource "aws_iam_role_policy_attachment" "mstr-environment-create-sfn-resource-policy-attachment" {
  role       = "${aws_iam_role.mstr-environment-create-sfn-role.name}"
  policy_arn = "${aws_iam_policy.mstr-environment-create-sfn-resource-policy.arn}"
}
