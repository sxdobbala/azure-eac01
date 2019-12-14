locals {
  vpc_id              = "${var.vpc_id}"
  allow_nat           = 0
  image_arn           = "${var.image_arn}"
  egress_port_numbers = ["${var.egress_port_numbers}"]
  list_of_aws_azs     = ["${var.list_of_aws_azs}"]
  subnet_count        = "${length(var.list_of_aws_azs)}"
  vpc_cidr_blocks     = ["${var.vpc_cidr_blocks}"]
  aws_region          = "${data.aws_region.current_region.name}"
  appstream_bucket    = "appstream2-36fb080bb8-${local.aws_region}-${data.aws_caller_identity.current_identity.account_id}"
  namespace_str       = "${var.env_prefix}-"
  namespace           = "${var.env_prefix != "" ? local.namespace_str : ""}"

  prefix_list_ids_by_region = {
    "us-east-1" = "pl-63a5400a"
    "us-west-2" = "pl-68a54001"
  }
}

data "aws_caller_identity" "current_identity" {}

data "aws_region" "current_region" {}

data "aws_vpc_endpoint" "s3" {
  vpc_id       = "${local.vpc_id}"
  service_name = "com.amazonaws.${local.aws_region}.s3"
}

module "appstream_subnets" {
  source                                         = "git::https://github.optum.com/oaccoe/aws_vpc.git//terraform_module/subnets?ref=v1.7.10"
  aws_region                                     = "${local.aws_region}"
  vpc_id                                         = "${local.vpc_id}"
  create_nacl_for_private_subnets                = true
  number_of_private_subnets                      = "${local.subnet_count}"
  list_of_aws_az                                 = ["${local.list_of_aws_azs}"]
  list_of_cidr_block_for_public_subnets          = []
  list_of_cidr_block_for_private_subnets         = ["${var.list_of_cidr_block_for_private_subnets}"]
  associate_s3_endpoint_with_private_route_table = true
  vpc_endpoint_s3_id                             = "${data.aws_vpc_endpoint.s3.id}"
  tag_name_identifier                            = "appstream-subnets"
  vpc_nat_gateway_ids                            = ["PLACEHOLDER"]                                                                          # TODO should not fail if not needed
  global_tags                                    = "${var.global_tags}"
}

resource "aws_network_acl_rule" "private_inbound_return_traffic_via_nat" {
  network_acl_id = "${module.appstream_subnets.subnets_private_nacl_id}"
  protocol       = "tcp"
  rule_number    = 120
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024                                                  # Allows inbound return traffic from the NAT device in the public subnet for requests originating in the private subnet
  to_port        = 65535                                                 #Ephemeral Port range is different for different OS
}

resource "aws_network_acl_rule" "outbound_http_from_private_subnet" {
  network_acl_id = "${module.appstream_subnets.subnets_private_nacl_id}"
  protocol       = "tcp"
  egress         = true
  rule_number    = 130
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "outbound_https_from_private_subnet" {
  network_acl_id = "${module.appstream_subnets.subnets_private_nacl_id}"
  protocol       = "tcp"
  egress         = true
  rule_number    = 140
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "outbound_response_to_internet_from_private_subnet" {
  network_acl_id = "${module.appstream_subnets.subnets_private_nacl_id}"
  protocol       = "tcp"
  egress         = true
  rule_number    = 150
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "outbound_ssh_to_vpc" {
  network_acl_id = "${module.appstream_subnets.subnets_private_nacl_id}"
  count          = "${length(local.vpc_cidr_blocks)}"
  egress         = true
  protocol       = "tcp"
  rule_number    = "${160 + count.index}"
  rule_action    = "allow"
  cidr_block     = "${local.vpc_cidr_blocks[count.index]}"
  from_port      = 22
  to_port        = 22
}

resource "aws_security_group" "appstream_sg" {
  name   = "${local.namespace}appstream-security-group"
  vpc_id = "${local.vpc_id}"

  tags = "${merge(var.global_tags, map("Name", "appstream"))}"
}

resource "aws_security_group_rule" "allow_other_ports_tcp_egress_vpc" {
  count             = "${length(local.egress_port_numbers)}"
  type              = "egress"
  from_port         = "${local.egress_port_numbers[count.index]}"
  to_port           = "${local.egress_port_numbers[count.index]}"
  protocol          = "tcp"
  security_group_id = "${aws_security_group.appstream_sg.id}"
  cidr_blocks       = ["${local.vpc_cidr_blocks}"]
}

resource "aws_security_group_rule" "allow_appstream_s3_egress" {
  type              = "egress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  security_group_id = "${aws_security_group.appstream_sg.id}"
  prefix_list_ids   = ["${local.prefix_list_ids_by_region[local.aws_region]}"] # access to S3
}

data "aws_iam_policy_document" "allow_user_streaming_doc" {
  statement {
    effect    = "Allow"
    actions   = ["appstream:DescribeStacks"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["appstream:Stream"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "appstream:userId"
      values   = ["&{saml:sub}"]
    }
  }
}

resource "aws_iam_policy" "allow_user_streaming_policy" {
  name        = "${local.namespace}appstream-user-policy"
  description = "Allow users to start appstream sesssions via federation when logged into console"
  policy      = "${data.aws_iam_policy_document.allow_user_streaming_doc.json}"
}

# Workaround for lack of Appstream support in TF natively
resource "aws_cloudformation_stack" "appstream_stack" {
  name = "${local.namespace}appstream-stack"

  parameters {
    ImageArn        = "${local.image_arn}"
    SecurityGroupId = "${aws_security_group.appstream_sg.id}"
    SubnetIds       = "${join(",", module.appstream_subnets.subnets_private_subnet_ids)}"
  }

  template_body = <<EOF
{
  "Parameters" : {
    "ImageArn" : {
      "Type" : "String",
      "Description" : "ARN of image to use"
    },
    "SecurityGroupId" : {
      "Type" : "String",
      "Description" : "ID of security group to use"
    },
    "SubnetIds" : {
      "Type" : "List<AWS::EC2::Subnet::Id>",
      "Description" : "List of subnet IDs"
    }
  },
 "Resources": {
  "opaFleet": {
    "Type": "AWS::AppStream::Fleet",
    "Properties" : {
        "ComputeCapacity": {"DesiredInstances": 1},
        "FleetType": "ON_DEMAND",
        "InstanceType": "stream.standard.large",
        "Description" : "OPA Break Glass fleet",
        "DisplayName" : "OPA Break Glass fleet",
        "Name": "OPABreakGlassFleet",
        "EnableDefaultInternetAccess" : false,
        "ImageArn" : {"Ref": "ImageArn"},
        "VpcConfig" : {
            "SecurityGroupIds" : [{"Ref": "SecurityGroupId"}],
            "SubnetIds" : {"Ref": "SubnetIds"}
        }
      }
    },
    "opaStack": {
      "Type" : "AWS::AppStream::Stack",
      "Properties" : {
            "ApplicationSettings" :
            {
              "Enabled": true,
              "SettingsGroup": "opaStackSettingsGroup"
            },
            "Description" : "OPA Break Glass stack",
            "DisplayName" : "OPA Break Glass stack",
            "Name" : "OPABreakGlassStack",
            "StorageConnectors" : [{"ConnectorType": "HOMEFOLDERS"}],
            "UserSettings" : [
              {"Action": "CLIPBOARD_COPY_FROM_LOCAL_DEVICE",
               "Permission": "ENABLED"},
              {"Action": "CLIPBOARD_COPY_TO_LOCAL_DEVICE",
                "Permission": "ENABLED"},
              {"Action": "FILE_DOWNLOAD",
               "Permission": "ENABLED"},
              {"Action": "FILE_UPLOAD",
               "Permission": "ENABLED"}
            ]
          }
    },
    "opaStackFleet": {
      "Type" : "AWS::AppStream::StackFleetAssociation",
      "DependsOn": ["opaStack", "opaFleet"],
      "Properties" : {
          "FleetName" : "OPABreakGlassFleet",
          "StackName" : "OPABreakGlassStack"
        }
    }
  }
}
EOF

  tags = "${var.global_tags}"
}

resource "aws_appautoscaling_target" "appstream_autoscale_target" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "fleet/OPABreakGlassFleet"
  role_arn           = "arn:aws:iam::${data.aws_caller_identity.current_identity.account_id}:role/aws-service-role/appstream.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_AppStreamFleet"
  scalable_dimension = "appstream:fleet:DesiredCapacity"
  service_namespace  = "appstream"

  depends_on = ["aws_cloudformation_stack.appstream_stack"]
}

resource "aws_appautoscaling_policy" "appstream_scaleout_policy" {
  name               = "${local.namespace}appstream-scaleout"
  policy_type        = "StepScaling"
  resource_id        = "fleet/OPABreakGlassFleet"
  scalable_dimension = "appstream:fleet:DesiredCapacity"
  service_namespace  = "appstream"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = 2
    }
  }

  depends_on = ["aws_appautoscaling_target.appstream_autoscale_target"]
}

resource "aws_cloudwatch_metric_alarm" "appstream_scaleout_alarm" {
  alarm_name          = "${local.namespace}appstream-scaleout-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "AvailableCapacity"
  namespace           = "AWS/AppStream"
  period              = "120"
  statistic           = "Average"
  threshold           = "1"
  unit                = "Count"

  dimensions = {
    Fleet = "OPABreakGlassFleet"
  }

  alarm_description = "Scale out alarm for appstream"
  alarm_actions     = ["${aws_appautoscaling_policy.appstream_scaleout_policy.arn}"]
}

resource "aws_appautoscaling_policy" "appstream_scalein_policy" {
  name               = "${local.namespace}appstream-scalein"
  policy_type        = "StepScaling"
  resource_id        = "fleet/OPABreakGlassFleet"
  scalable_dimension = "appstream:fleet:DesiredCapacity"
  service_namespace  = "appstream"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = ["aws_appautoscaling_target.appstream_autoscale_target"]
}

resource "aws_cloudwatch_metric_alarm" "appstream_scalein_alarm" {
  alarm_name          = "${local.namespace}appstream-scalein-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "AvailableCapacity"
  namespace           = "AWS/AppStream"
  period              = "120"
  statistic           = "Average"
  threshold           = "3"
  unit                = "Count"

  dimensions = {
    Fleet = "OPABreakGlassFleet"
  }

  alarm_description = "Scale in alarm for appstream"
  alarm_actions     = ["${aws_appautoscaling_policy.appstream_scalein_policy.arn}"]
}

resource "aws_s3_bucket_policy" "appstream_settings_require_ssl" {
  # see: https://docs.aws.amazon.com/appstream2/latest/developerguide/home-folders.html#home-folders-s3

  bucket = "${local.appstream_bucket}"
  policy = "${data.aws_iam_policy_document.appstream_bucket_policy.json}"

  depends_on = ["aws_cloudformation_stack.appstream_stack"]
}

# Policy to enforce SSL data transfer
data "aws_iam_policy_document" "appstream_bucket_policy" {
  statement {
    sid     = "DenyInsecureCommunications"
    actions = ["s3:*"]
    effect  = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = ["arn:aws:s3:::${local.appstream_bucket}/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid     = "PreventAccidentalDeletionOfBucket"
    actions = ["s3:DeleteBucket"]
    effect  = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = ["arn:aws:s3:::${local.appstream_bucket}"]
  }
}
