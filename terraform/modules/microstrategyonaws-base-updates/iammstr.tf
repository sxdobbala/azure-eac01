resource "aws_iam_policy" "mstr_ec2_policy" {
  description = "Allow custom actions for MSTR EC2 instances"

  policy = "${data.aws_iam_policy_document.mstr_ec2_policy_document.json}"
}

data "aws_iam_policy_document" "mstr_ec2_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter", "ssm:PutParameter", "ssm:GetParametersByPath"]
    resources = ["*"]                                                               #TODO - make more restrictive
  }

  statement {
    effect    = "Allow"
    actions   = [
                  "states:SendTaskSuccess",
                  "states:SendTaskFailure"
                ]
    resources = ["*"]                                    #TODO - make more restrictive
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListObjects",
      "s3:GetEncryptionConfiguration",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
    ]

    resources = ["arn:aws:s3:::${var.artifacts_s3_bucket}", "arn:aws:s3:::${var.artifacts_s3_bucket}/*"]
  }
}

resource "null_resource" "mstr_stack_dependency" {
  triggers {
    stack_name = "${aws_cloudformation_stack.MicroStrategyOnAWS.id}"
  }

  provisioner "local-exec" {
    command = "echo ${aws_cloudformation_stack.MicroStrategyOnAWS.id}"
  }
}

resource "aws_iam_role_policy_attachment" "role-platform-instance-policy" {
  role       = "MSTRInstanceProfileRole-${data.aws_region.current.name}"
  policy_arn = "${aws_iam_policy.mstr_ec2_policy.arn}"

  depends_on = ["null_resource.mstr_stack_dependency"]
}

resource "aws_iam_role_policy_attachment" "role-platform-ssm-ec2-role" {
  role       = "MSTRInstanceProfileRole-${data.aws_region.current.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

  depends_on = ["null_resource.mstr_stack_dependency"]
}

resource "aws_iam_role_policy_attachment" "role-platform-cloudwatch-agent-admin-role" {
  role       = "MSTRInstanceProfileRole-${data.aws_region.current.name}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentAdminPolicy"

  depends_on = ["null_resource.mstr_stack_dependency"]
}
