locals {
  aws_account_id  = "${data.aws_caller_identity.current_identity.account_id}"
  aws_region_name = "${data.aws_region.current_region.name}"

  ec2_security_groups = ["${aws_security_group.dataloader_ec2_sg.id}",
    "${var.redshift_egress_security_group_id}",
  ]

  ports = ["${var.is_https_enabled == "true" ? var.elb_https_port : ""}",
    "${var.is_http_enabled == "true" ? var.elb_http_port : ""}",
  ]

  elb_listener_ports = "${compact(local.ports)}"
  env_name           = "${var.env_prefix}-${var.app_name}"
}

data "aws_caller_identity" "current_identity" {}
data "aws_region" "current_region" {}

# Service role
resource "aws_iam_role" "dataloader_eb_service_role" {
  name        = "${local.env_name}-eb-service-role"
  description = "Allows Elastic Beanstalk to create and manage AWS resources on your behalf"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticbeanstalk.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "elasticbeanstalk"
        }
      }
    }
  ]
}
EOF

  tags = "${merge(var.global_tags, map("Name", "${local.env_name}-eb-service-role"))}"
}

resource "aws_iam_role_policy_attachment" "dataloader_eb_service_role_policy_eb_service" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
  role       = "${aws_iam_role.dataloader_eb_service_role.name}"
}

resource "aws_iam_role_policy_attachment" "dataloader_eb_service_role_policy_eb_enhanced_health" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
  role       = "${aws_iam_role.dataloader_eb_service_role.name}"
}

# EC2 IAM profile
resource "aws_iam_instance_profile" "dataloader_ec2_iam_profile" {
  name = "${local.env_name}-ec2-iam-profile"
  role = "${module.dataloader_ec2_iam_role.role_name}"
}

module "dataloader_ec2_iam_role" {
  source                             = "git::https://github.optum.com/CommercialCloud-EAC/aws_iam.git//terraform_module/role?ref=v1.0.3"
  role_name                          = "${local.env_name}-ec2-iam-role"
  role_description                   = "Role for dataloader EC2 instances"
  role_assumerole_service_principals = ["ec2.amazonaws.com"]
  role_custom_managed_policy_count   = 3

  role_custom_managed_policy = [
    # TODO: We may need to restrict this policy's SSM permissions.
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",

    "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier",
    "${module.dataloader_managed_policy.policy_arn}",
  ]

  global_tags = "${merge(var.global_tags, map("Name", "${local.env_name}-ec2-iam-role"))}"
}

module "dataloader_managed_policy" {
  source             = "git::https://github.optum.com/CommercialCloud-EAC/aws_iam.git//terraform_module/policy?ref=v1.0.3"
  policy_name        = "${local.env_name}-managed-policy"
  policy_path        = "/"
  policy_description = "Policy for dataloader EC2 IAM profile"
  policy_document    = "${data.aws_iam_policy_document.dataloader_managed_policy_document.json}"
}

data "aws_iam_policy_document" "dataloader_managed_policy_document" {
  statement {
    sid       = "AllowInvokeFunction"
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = ["arn:aws:lambda:${local.aws_region_name}:${local.aws_account_id}:function:${var.env_prefix}-opa-opa-master"]
  }

  statement {
    sid     = "AllowGetParameter"
    effect  = "Allow"
    actions = ["ssm:GetParameter"]

    resources = ["arn:aws:ssm:${local.aws_region_name}:${local.aws_account_id}:parameter/${var.env_prefix}/dataloader*",
      "arn:aws:ssm:${local.aws_region_name}:${local.aws_account_id}:parameter/*-redshift-cluster.H*.password",
    ]
  }

  statement {
    sid       = "AllowDescribeCluster"
    effect    = "Allow"
    actions   = ["redshift:DescribeClusters"]
    resources = ["*"]
  }

  statement {
    sid     = "AllowClusterCredentials"
    effect  = "Allow"
    actions = ["redshift:GetClusterCredentials"]

    resources = [
      "arn:aws:redshift:${local.aws_region_name}:${local.aws_account_id}:dbuser:*-redshift-cluster/h*_user",
      "arn:aws:redshift:${local.aws_region_name}:${local.aws_account_id}:dbname:*-redshift-cluster/h*",
    ]
  }

  statement {
    sid       = "AllowDeleteObject"
    effect    = "Allow"
    actions   = ["s3:DeleteObject"]
    resources = ["arn:aws:s3:::${var.s3_bucket_id}/dataloader-opa-plugins/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetEncryptionConfiguration",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]

    resources = ["arn:aws:s3:::${var.s3_bucket_id}", "arn:aws:s3:::${var.s3_bucket_id}/*"]
  }
}

# ELB security group
resource "aws_security_group" "dataloader_elb_sg" {
  name        = "${local.env_name}-elb-sg"
  description = "Security group for ${local.env_name} ELB"
  vpc_id      = "${var.vpc_id}"
  tags        = "${merge(var.global_tags, map("Name", "${local.env_name}-elb-sg"))}"
}

resource "aws_security_group_rule" "dataloader_elb_sg_from_hybrid" {
  count             = "${(var.is_hybrid == "true" ? 1 : 0) * length(local.elb_listener_ports)}"
  type              = "ingress"
  security_group_id = "${aws_security_group.dataloader_elb_sg.id}"
  from_port         = "${local.elb_listener_ports[count.index]}"
  to_port           = "${local.elb_listener_ports[count.index]}"
  protocol          = "tcp"
  cidr_blocks       = ["${var.hybrid_subnet_cidr_blocks}"]
  description       = "Allow inbound from hybrid network"
}

resource "aws_security_group" "dataloader_egress_sg" {
  name        = "${var.env_prefix}-dataloader-egress-sg"
  description = "Security group for ${var.env_prefix} dataloader egress sg "
  vpc_id      = "${var.vpc_id}"
  tags        = "${merge(var.global_tags, map("Name", "${var.env_prefix}-dataloader-egress-sg"))}"
}

resource "aws_security_group_rule" "dataloader_elb_ingress_from_egress_sg" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.dataloader_elb_sg.id}"
  source_security_group_id = "${aws_security_group.dataloader_egress_sg.id}"
}

resource "aws_security_group_rule" "dataloader_elb_ingress_from_vpc" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.dataloader_elb_sg.id}"
  cidr_blocks       = ["${var.vpc_cidr_block}"]
  description       = "Allow inbound from VPC"
}

resource "aws_security_group_rule" "dataloader_egress_to_elb" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.dataloader_egress_sg.id}"
  source_security_group_id = "${aws_security_group.dataloader_elb_sg.id}"
}

# EC2 security group
resource "aws_security_group" "dataloader_ec2_sg" {
  name        = "${local.env_name}-ec2-sg"
  description = "Security group for ${local.env_name} EC2"
  vpc_id      = "${var.vpc_id}"

  # Allow outbound access to internet. This is needed mainly to allow AWS services to work.
  # TODO: Restrict/Control all outbound internet access via proxy and/or AWS service endpoints
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(var.global_tags, map("Name", "${local.env_name}-ec2-sg"))}"
}

resource "aws_security_group_rule" "dataloader_ec2_sg_from_elb" {
  type                     = "ingress"
  security_group_id        = "${aws_security_group.dataloader_ec2_sg.id}"
  source_security_group_id = "${aws_security_group.dataloader_elb_sg.id}"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  description              = "Allow inbound from dataloader elb"
}

resource "aws_security_group_rule" "dataloader_elb_sg_to_ec2" {
  type                     = "egress"
  security_group_id        = "${aws_security_group.dataloader_elb_sg.id}"
  source_security_group_id = "${aws_security_group.dataloader_ec2_sg.id}"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  description              = "Allow outbound to dataloder ec2"
}

data "aws_security_group" "dataloader_ec2_auto_sg" {
  depends_on = ["aws_elastic_beanstalk_environment.dataloader_eb_env"]

  tags = {
    Name = "${local.env_name}"
  }
}

# Despite using our own security group, eb ends up creating default security group in addition to using the one we pass.
# This removes the wide open outbound rule on auto generated SG.
resource "null_resource" "dataloader_ec2_auto_sg_remove_egress_allow_all" {
  provisioner "local-exec" {
    command = "aws ec2 revoke-security-group-egress --group-id ${data.aws_security_group.dataloader_ec2_auto_sg.id} --protocol all --port 0 --cidr 0.0.0.0/0"
  }
}

# Private CA signed cert

data "aws_ssm_parameter" "ca_public_cert" {
  name = "${var.ca_public_cert_ssm_param_name}"
}

data "aws_ssm_parameter" "ca_private_key" {
  name = "${var.ca_private_key_ssm_param_name}"
}

resource "tls_private_key" "dataloader_private_key" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "dataloader_cert_request" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.dataloader_private_key.private_key_pem}"
  dns_names       = ["${local.env_name}.${data.aws_region.current_region.name}.elasticbeanstalk.com"]

  subject {
    common_name = "${local.env_name}.${data.aws_region.current_region.name}.elasticbeanstalk.com"
  }
}

resource "tls_locally_signed_cert" "dataloader_cert" {
  cert_request_pem      = "${tls_cert_request.dataloader_cert_request.cert_request_pem}"
  ca_key_algorithm      = "RSA"
  ca_private_key_pem    = "${data.aws_ssm_parameter.ca_private_key.value}"
  ca_cert_pem           = "${data.aws_ssm_parameter.ca_public_cert.value}"
  validity_period_hours = 8760                                                           # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_iam_server_certificate" "dataloader_iam_cert" {
  name             = "${local.env_name}"
  certificate_body = "${tls_locally_signed_cert.dataloader_cert.cert_pem}"
  private_key      = "${tls_private_key.dataloader_private_key.private_key_pem}"
}

# Elastic beanstalk environment

data "aws_elastic_beanstalk_application" "dataloader_eb_app" {
  name = "${var.app_name}"
}

resource "aws_elastic_beanstalk_configuration_template" "template" {
  # Make sure to update the version number in the template name whenever the template is updated otherwise the changes won't go in effect.
  # Template name needs to be unique everytime you want to update the congifuration of beanstalk dataloader environemnt.
  # It's a known terraform design issue. There's most likely a fix in v0.12+
  name = "${local.env_name}-config-v1"

  application = "${data.aws_elastic_beanstalk_application.dataloader_eb_app.id}"

  # NOTE: Ensure the solution stack name matches with current ebs stack version.
  # If the solution stack name doesn't match to the current version, ebs will end up re-creating the EC2 instances. Thus, avoid applying changes in prod during buisness hours.
  solution_stack_name = "${var.solution_stack_name}"

  # Environment
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "${var.environment_type}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "${var.elb_type}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "${aws_iam_role.dataloader_eb_service_role.name}"
  }

  # Auto scaling
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = "${join(",", local.ec2_security_groups)}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "${aws_iam_instance_profile.dataloader_ec2_iam_profile.arn}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "${var.ec2_instance_type}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "MonitoringInterval"
    value     = "1 minute"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "${var.autoscale_min}"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "${var.autoscale_max}"
  }

  # Network
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "${var.vpc_id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "internal"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${join(",", var.private_subnet_ids)}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${join(",", var.private_subnet_ids)}"
  }

  # Load balancer
  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SecurityGroups"
    value     = "${aws_security_group.dataloader_elb_sg.id}"
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "ManagedSecurityGroup"
    value     = "${aws_security_group.dataloader_elb_sg.id}"
  }

  setting {
    namespace = "aws:elbv2:listener:default"
    name      = "ListenerEnabled"
    value     = "${var.elb_http_port == "80" ? var.is_http_enabled : "false"}"
  }

  setting {
    namespace = "aws:elbv2:listener:${var.elb_http_port}"
    name      = "ListenerEnabled"
    value     = "${var.elb_http_port != "80" ? var.is_http_enabled : "false"}"
  }

  setting {
    namespace = "aws:elbv2:listener:${var.elb_https_port}"
    name      = "ListenerEnabled"
    value     = "${var.is_https_enabled}"
  }

  setting {
    namespace = "aws:elbv2:listener:${var.elb_https_port}"
    name      = "Protocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elbv2:listener:${var.elb_https_port}"
    name      = "SSLCertificateArns"
    value     = "${aws_iam_server_certificate.dataloader_iam_cert.arn}"
  }

  setting {
    namespace = "aws:elbv2:listener:${var.elb_https_port}"
    name      = "SSLPolicy"
    value     = "${var.elb_ssl_policy}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application"
    name      = "Application Healthcheck URL"
    value     = "${var.healthcheck_url}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "${var.healthcheck_url}"
  }

  # Logs
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "DeleteOnTerminate"
    value     = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = "30"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
    name      = "HealthStreamingEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
    name      = "DeleteOnTerminate"
    value     = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
    name      = "RetentionInDays"
    value     = "30"
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "AccessLogsS3Enabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "AccessLogsS3Bucket"
    value     = "${var.elb_logs_bucket_id}"
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "AccessLogsS3Prefix"
    value     = "${local.env_name}"
  }

  # Deployment preferences
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = "Rolling"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSizeType"
    value     = "Fixed"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSize"
    value     = "1"
  }

  # Managed actions
  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "ManagedActionsEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "PreferredStartTime"
    value     = "Sun:02:00"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "UpdateLevel"
    value     = "minor"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "InstanceRefreshEnabled"
    value     = "true"
  }

  # Environment variables
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_S3_BUCKET_NAME"
    value     = "${var.s3_bucket_id}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DATALOADER_ENV"
    value     = "${var.env_prefix}"
  }
}

resource "aws_elastic_beanstalk_environment" "dataloader_eb_env" {
  name          = "${local.env_name}"
  application   = "${data.aws_elastic_beanstalk_application.dataloader_eb_app.id}"
  cname_prefix  = "${local.env_name}"
  tier          = "WebServer"
  tags          = "${var.global_tags}"
  template_name = "${aws_elastic_beanstalk_configuration_template.template.name}"
}
