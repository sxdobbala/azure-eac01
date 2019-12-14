#############################################################################################
# Step function to create MSTR backup
#############################################################################################

data "template_file" "mstr-backup-sfn-definition" {
  template = "${file("${path.module}/definitions/mstr-backup.json")}"

  vars {
    MSTR_BACKUP_LAMBDA_ARN = "${var.opa_mstr_backup_lambda_arn}"
  }
}

resource "aws_sfn_state_machine" "mstr-backup-sfn" {
  name       = "${var.env_prefix}-mstr-backup-sfn"
  role_arn   = "${aws_iam_role.mstr-backup-sfn-role.arn}"
  definition = "${data.template_file.mstr-backup-sfn-definition.rendered}"
  tags       = "${var.global_tags}"
}

data "aws_iam_policy_document" "mstr-backup-sfn-role-document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.${local.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "mstr-backup-sfn-role" {
  name               = "${var.env_prefix}-mstr-backup-sfn-role"
  assume_role_policy = "${data.aws_iam_policy_document.mstr-backup-sfn-role-document.json}"
}

data "aws_iam_policy_document" "mstr-backup-sfn-resource-policy-document" {
  statement {
    effect  = "Allow"
    actions = ["lambda:InvokeFunction"]

    resources = [
      "${var.opa_mstr_backup_lambda_arn}",
    ]
  }
}

resource "aws_iam_policy" "mstr-backup-sfn-resource-policy" {
  name        = "${var.env_prefix}-mstr-backup-sfn-lambda"
  description = "Lambdas that the mstr-environment step function can invoke"
  policy      = "${data.aws_iam_policy_document.mstr-backup-sfn-resource-policy-document.json}"
}

resource "aws_iam_role_policy_attachment" "mstr-backup-sfn-resource-policy-attachment" {
  role       = "${aws_iam_role.mstr-backup-sfn-role.name}"
  policy_arn = "${aws_iam_policy.mstr-backup-sfn-resource-policy.arn}"
}
