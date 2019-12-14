/*
    This tf file is to create opa-release specific SNS Topic and role.
*/

# create a SNS topic for opa-release step function
resource "aws_sns_topic" "opa-release-setup-sns-topic" {
  name = "${var.env_prefix}-opa-release-sns-topic"
}

# this role allows SSM to post events to an SNS topic when command invocations complete
resource "aws_iam_role" "opa-release-setup-sns-role" {
  name = "${var.env_prefix}-opa-release-sns-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAssumeRoleToEC2Service",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
     },
     "Action": "sts:AssumeRole"
   },
   {
      "Sid": "AllowAssumeRoleToSSMService",
      "Effect": "Allow",
      "Principal": {
        "Service": "ssm.amazonaws.com"
     },
     "Action": "sts:AssumeRole"
   }
 ]
}
EOF

  tags = "${var.global_tags}"
}

resource "aws_iam_policy" "opa-release-setup-sns-role-access-policy" {
  name        = "${var.env_prefix}-opa-release-sns-topic-role-access-policy"
  description = "Set SNS Access for opa-release-sns-topic-role"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowPublishToSNSTopic",
            "Effect": "Allow",
            "Action": "sns:Publish",
            "Resource": "${aws_sns_topic.opa-release-setup-sns-topic.arn}"
        }
    ]
}
EOF
}

# add SNS Access policy to opa-release-sns-topic-role
resource "aws_iam_role_policy_attachment" "opa-release-setup-sns-role-policy" {
  policy_arn = "${aws_iam_policy.opa-release-setup-sns-role-access-policy.arn}"
  role       = "${aws_iam_role.opa-release-setup-sns-role.name}"
}
