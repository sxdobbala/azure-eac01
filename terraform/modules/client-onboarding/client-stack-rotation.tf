data "template_file" "client-stack-rotation-sfn-definition" {
  template = "${file("${path.module}/definitions/client-stack-rotation.json")}"

  vars {
    OPA_MASTER_LAMBDA_ARN                   = "${var.opa_master_lambda_arn}"
    OPA_CLIENT_REDSHIFT_SECURITY_LAMBDA_ARN = "${var.opa_client_redshift_security_lambda_arn}"
    OPA_DEPLOY_RW_SCHEMA_LAMBDA_ARN         = "${var.opa_deploy_rw_schema_lambda_arn}"
    OPA_SMOKE_TEST_LAMBDA_ARN               = "${var.opa_smoke_test_lambda_arn}"
    OPA_CLIENT_ENV_MOVE_LAMBDA_ARN          = "${var.opa_client_env_move_lambda_arn}"
    OPA_TIMEZONE_CHANGE_LAMBDA_ARN          = "${var.opa_timezone_change_lambda_arn}"

    # tf-runner lambda
    TF_RUNNER_LAMBDA_ARN      = "${var.opa_tf_runner_lambda_arn}"
    TF_SOURCE_BUCKET          = "${var.artifacts_s3_bucket}"
    TF_SOURCE_KEY             = "${var.opa_mstr_aws_archive_s3_key}"
    ENV_PREFIX                = "${var.env_prefix}"
    OPA_RELEASE_SNS_TOPIC_ARN = "${var.opa_release_sns_topic_arn}"
    VPC_ID                    = "${var.vpc_id}"
  }
}

resource "aws_sfn_state_machine" "client-stack-rotation-sfn" {
  name       = "${var.env_prefix}-client-stack-rotation-sfn"
  role_arn   = "${aws_iam_role.client-stack-rotation-sfn-role.arn}"
  definition = "${data.template_file.client-stack-rotation-sfn-definition.rendered}"
  tags       = "${var.global_tags}"
}

data "aws_iam_policy_document" "client-stack-rotation-sfn-role-document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.${local.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "client-stack-rotation-sfn-role" {
  name               = "${var.env_prefix}-client-stack-rotation-sfn-role"
  assume_role_policy = "${data.aws_iam_policy_document.client-stack-rotation-sfn-role-document.json}"
}

data "aws_iam_policy_document" "client-stack-rotation-sfn-resource-policy-document" {
  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]

    resources = [
      "${var.opa_client_env_move_lambda_arn}",
      "${var.opa_client_redshift_security_lambda_arn}",
      "${var.opa_tf_runner_lambda_arn}",
      "${var.opa_smoke_test_lambda_arn}",
      "${var.opa_timezone_change_lambda_arn}",
    ]
  }
}

resource "aws_iam_policy" "client-stack-rotation-sfn-resource-policy" {
  name        = "${var.env_prefix}-client-stack-rotation-sfn-resource-policy"
  description = "Resources that the client-onboarding step function can invoke"
  policy      = "${data.aws_iam_policy_document.client-stack-rotation-sfn-resource-policy-document.json}"
}

resource "aws_iam_role_policy_attachment" "client-stack-rotation-sfn-resource-policy-attachment" {
  role       = "${aws_iam_role.client-stack-rotation-sfn-role.name}"
  policy_arn = "${aws_iam_policy.client-stack-rotation-sfn-resource-policy.arn}"
}
