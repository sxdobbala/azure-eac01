data "aws_caller_identity" "current" {}

locals {
  provisioner_count = "${var.state == "stop" ? 0 : 1}"
  tags              = "${merge(var.global_tags, map("optum:customer", var.customer))}"
}

resource "random_id" "server" {
  keepers = {
    # Generate a new id each time we switch to a new AMI id	
    name = "${var.environmentName}"
  }

  byte_length = 4
}

resource "null_resource" "mstr_provisioner" {
  count = "${local.provisioner_count}"

  provisioner "local-exec" {
    command     = "python3 '${path.module}/createenvironment.py' --terraformId ${random_id.server.dec}"
    on_failure  = "fail"
    interpreter = ["bash", "-c"]                                                                        # so it will also work on cygwin

    environment = {
      environmentName      = "${var.environmentName}"
      environmentType      = "${var.environmentType}"
      microStrategyVersion = "${var.microStrategyVersion}"
      mstrbak              = "${var.mstrbak}"
      apikey               = "${var.apikey}"
      firstName            = "${var.firstName}"
      lastName             = "${var.lastName}"

      email   = "${var.email}"
      company = "${var.company}"

      developerInstanceType = "${var.developerInstanceType}"
      platformInstanceType  = "${var.platformInstanceType}"
      platformOS            = "${var.platformOS}"
      rdsInstanceType       = "${var.rdsInstanceType}"

      rdsSize    = "${var.rdsSize}"
      awsAccount = "${data.aws_caller_identity.current.account_id}"
    }
  }

  provisioner "local-exec" {
    when       = "destroy"
    command    = "python3 ${path.module}/stopanddestroyenvironment.py --terraformId ${random_id.server.dec}"
    on_failure = "fail"
  }
}

data "aws_ssm_parameter" "environmentid" {
  name       = "tf-${random_id.server.dec}.mstr.envid"
  depends_on = ["null_resource.mstr_provisioner"]
}

locals {
  environmentId = "${data.aws_ssm_parameter.environmentid.value}"
}

module "opa-mstr" {
  source                    = "../opa-mstr"
  env_prefix                = "${var.env_prefix}"
  mstr_stack_name           = "env-${local.environmentId}"
  global_tags               = "${local.tags}"
  environmentName           = "${var.environmentName}"
  opa_release_sns_topic_arn = "${var.opa_release_sns_topic_arn}"
}

resource "aws_sns_topic" "codedeploytopic" {
  name = "mstrcodedeploy-env-${random_id.server.dec}"
}

resource "aws_codedeploy_deployment_group" "mstr-codedeploy-group-platform" {
  app_name               = "MSTRCodeDeploy"
  deployment_group_name  = "env-${data.aws_ssm_parameter.environmentid.value}-platform"
  service_role_arn       = "${aws_iam_role.mstrcodedeploy.arn}"
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  trigger_configuration {
    trigger_events     = ["DeploymentFailure"]
    trigger_name       = "failed"
    trigger_target_arn = "${aws_sns_topic.codedeploytopic.arn}"
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "aws:cloudformation:stack-name"
      type  = "KEY_AND_VALUE"
      value = "env-${data.aws_ssm_parameter.environmentid.value}"
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
    ignore_changes = ["id", "ec2_tag_set", "trigger_configuration"]
  }
}

resource "aws_iam_role" "mstrcodedeploy" {
  name = "mstrcodedeploy-${local.environmentId}" #

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

  tags = "${local.tags}"
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = "${aws_iam_role.mstrcodedeploy.name}"

  lifecycle {
    ignore_changes = ["id"]
  }
}

resource "aws_ssm_parameter" "app_elb_path_mstr" {
  name      = "/env-${local.environmentId}/elb_path"
  type      = "String"
  value     = "${var.app_elb_path}"
  overwrite = true

  #tags      = "${var.global_tags}"

  lifecycle = {
    ignore_changes = ["id", "name"]
  }
}

resource "aws_ssm_parameter" "customer" {
  name      = "/env-${local.environmentId}/customer"
  type      = "String"
  value     = "${var.customer}"
  overwrite = true
}

resource "aws_ssm_parameter" "env_prefix" {
  name      = "/env-${local.environmentId}/env_prefix"
  type      = "String"
  value     = "${var.env_prefix}"
  overwrite = true
}
