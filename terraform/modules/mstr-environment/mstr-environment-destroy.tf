#############################################################################################
# Step function to destroy a MSTR environment - main entry point for workflow which combines
# destruction of MSTR stack and other resources.
#############################################################################################

data "template_file" "mstr-environment-destroy-sfn-definition" {
  template = "${file("${path.module}/definitions/mstr-environment-destroy.json")}"

  vars {
    # state machines
    MSTR_STACK_DESTROY_SFN_ARN = "${aws_sfn_state_machine.mstr-stack-destroy-sfn.id}"

    # tf-runner lambda
    TF_RUNNER_LAMBDA_ARN      = "${var.opa_tf_runner_lambda_arn}"
    TF_SOURCE_BUCKET          = "${var.artifacts_s3_bucket}"
    TF_SOURCE_KEY             = "${var.opa_mstr_aws_archive_s3_key}"
    ENV_PREFIX                = "${var.env_prefix}"
    OPA_RELEASE_SNS_TOPIC_ARN = "${var.opa_release_sns_topic_arn}"
    VPC_ID                    = "${var.vpc_id}"
  }
}

resource "aws_sfn_state_machine" "mstr-environment-destroy-sfn" {
  name       = "${var.env_prefix}-mstr-environment-destroy-sfn"
  role_arn   = "${aws_iam_role.mstr-environment-destroy-sfn-role.arn}"
  definition = "${data.template_file.mstr-environment-destroy-sfn-definition.rendered}"
  tags       = "${var.global_tags}"
}

data "aws_iam_policy_document" "mstr-environment-destroy-sfn-role-document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.${local.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "mstr-environment-destroy-sfn-role" {
  name               = "${var.env_prefix}-mstr-environment-destroy-sfn-role"
  assume_role_policy = "${data.aws_iam_policy_document.mstr-environment-destroy-sfn-role-document.json}"
}

data "aws_iam_policy_document" "mstr-environment-destroy-sfn-resource-policy-document" {
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

resource "aws_iam_policy" "mstr-environment-destroy-sfn-resource-policy" {
  name        = "${var.env_prefix}-mstr-environment-destroy-sfn-lambda"
  description = "Lambdas that the mstr-environment step function can invoke"
  policy      = "${data.aws_iam_policy_document.mstr-environment-destroy-sfn-resource-policy-document.json}"
}

resource "aws_iam_role_policy_attachment" "mstr-environment-destroy-sfn-resource-policy-attachment" {
  role       = "${aws_iam_role.mstr-environment-destroy-sfn-role.name}"
  policy_arn = "${aws_iam_policy.mstr-environment-destroy-sfn-resource-policy.arn}"
}
