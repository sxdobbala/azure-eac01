resource "aws_codedeploy_deployment_group" "mstr-codedeploy-group-platform" {
  app_name               = "MSTRCodeDeploy"
  deployment_group_name  = "${var.env_prefix}-${var.env_id}-platform"
  service_role_arn       = "${aws_iam_role.mstrcodedeploy.arn}"
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
      value = "${var.env_id}"
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

resource "aws_iam_role" "mstrcodedeploy" {
  name = "mstrcodedeploy-${var.env_id}" #

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
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = "${aws_iam_role.mstrcodedeploy.name}"

  lifecycle {
    ignore_changes = ["id"]
  }
}

resource "aws_ssm_parameter" "app_elb_path_mstr" {
  name      = "/${var.env_id}/elb_path"
  type      = "String"
  value     = "${var.app_elb_path}"
  overwrite = true
}

resource "aws_ssm_parameter" "env_prefix" {
  name      = "/${var.env_id}/env_prefix"
  type      = "String"
  value     = "${var.env_prefix}"
  overwrite = true
}
