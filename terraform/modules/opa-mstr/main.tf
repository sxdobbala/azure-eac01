locals {
  codedeploy_app_name = "${var.env_prefix}-OPA"
}

resource "aws_codedeploy_deployment_group" "opa_codedeploy_group_platform" {
  app_name               = "${local.codedeploy_app_name}"
  deployment_group_name  = "${local.codedeploy_app_name}-${var.mstr_stack_name}-platform"
  service_role_arn       = "${aws_iam_role.opa_codedeploy_role.arn}"
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  trigger_configuration {
    trigger_events     = ["DeploymentSuccess", "DeploymentFailure"]
    trigger_name       = "opa-release-sns-topic-trigger"
    trigger_target_arn = "${var.opa_release_sns_topic_arn}"
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "aws:cloudformation:stack-name"
      type  = "KEY_AND_VALUE"
      value = "${var.mstr_stack_name}"
    }
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "aws:cloudformation:logical-id"
      type  = "KEY_AND_VALUE"
      value = "PlatformInstance*"
    }
  }

  lifecycle {
    ignore_changes = ["id", "ec2_tag_set"]
  }
}

resource "aws_iam_role" "opa_codedeploy_role" {
  name = "${var.env_prefix}-opa-codedeploy-${var.mstr_stack_name}"

  lifecycle {
    ignore_changes = ["*"]
  }

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
     },
     "Action": "sts:AssumeRole"
   }
 ]
}
EOF

  tags = "${var.global_tags}"
}

resource "aws_iam_role_policy_attachment" "opa_codedeploy_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = "${aws_iam_role.opa_codedeploy_role.name}"

  lifecycle {
    ignore_changes = ["id"]
  }
}

resource "aws_ssm_parameter" "env_name" {
  name      = "/${var.mstr_stack_name}/env_name"
  type      = "String"
  value     = "${var.environmentName}"
  overwrite = "true"
}
