#############################################################################################
# Step function to destroy a MSTR stack
#############################################################################################

data "template_file" "mstr-stack-destroy-sfn-definition" {
  template = "${file("${path.module}/definitions/mstr-stack-destroy.json")}"

  vars {
    MSTR_ENVIRONMENT_LAMBDA_ARN  = "${var.opa_mstr_stack_lambda_arn}"
    MSTR_STACK_STATUS_LAMBDA_ARN = "${module.mstr-stack-status-lambda.arn}"
    AWS_REGION                   = "${local.aws_region}"
    AWS_ACCOUNT_ID               = "${local.account_id}"
    MSTR_VERSION                 = "${var.mstr_version}"
    MSTR_EMAIL                   = "${var.mstr_email}"
  }
}

resource "aws_sfn_state_machine" "mstr-stack-destroy-sfn" {
  name       = "${var.env_prefix}-mstr-stack-destroy-sfn"
  role_arn   = "${aws_iam_role.mstr-stack-destroy-sfn-role.arn}"
  definition = "${data.template_file.mstr-stack-destroy-sfn-definition.rendered}"
  tags       = "${var.global_tags}"
}

data "aws_iam_policy_document" "mstr-stack-destroy-sfn-role-document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.${local.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "mstr-stack-destroy-sfn-role" {
  name               = "${var.env_prefix}-mstr-stack-destroy-sfn-role"
  assume_role_policy = "${data.aws_iam_policy_document.mstr-stack-destroy-sfn-role-document.json}"
}

data "aws_iam_policy_document" "mstr-stack-destroy-sfn-resource-policy-document" {
  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]

    resources = [
      "${var.opa_mstr_stack_lambda_arn}",
      "${module.mstr-stack-status-lambda.arn}",
    ]
  }
}

resource "aws_iam_policy" "mstr-stack-destroy-sfn-resource-policy" {
  name        = "${var.env_prefix}-mstr-stack-destroy-sfn-lambda"
  description = "Lambdas that the mstr-environment step function can invoke"
  policy      = "${data.aws_iam_policy_document.mstr-stack-destroy-sfn-resource-policy-document.json}"
}

resource "aws_iam_role_policy_attachment" "mstr-stack-destroy-sfn-resource-policy-attachment" {
  role       = "${aws_iam_role.mstr-stack-destroy-sfn-role.name}"
  policy_arn = "${aws_iam_policy.mstr-stack-destroy-sfn-resource-policy.arn}"
}
