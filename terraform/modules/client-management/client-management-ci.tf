data "template_file" "client-management-ci-sfn-definition" {
  template = "${file("${path.module}/definitions/client-management-ci.json")}"

  vars {
    ENV_PREFIX                       = "${var.env_prefix}"
    CLIENT_MANAGEMENT_SFN_ARN        = "${aws_sfn_state_machine.client-management-sfn.id}"
    MSTR_ENVIRONMENT_DESTROY_SFN_ARN = "${var.mstr_environment_destroy_sfn_arn}"
    NOTIFICATION_SNS_TOPIC           = "${var.ci_sns_topic}"
  }
}

resource "aws_sfn_state_machine" "client-management-ci-sfn" {
  name       = "${var.env_prefix}-client-management-ci-sfn"
  role_arn   = "${aws_iam_role.client-management-sfn-role.arn}"
  definition = "${data.template_file.client-management-ci-sfn-definition.rendered}"
  tags       = "${var.global_tags}"
}
