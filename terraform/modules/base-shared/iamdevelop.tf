locals {
  # set count to 1 for those which need to be created during a nonprod run
  nonprod_count = "${var.is_prod == "true" ? 0 : 1}"

  # set multiplier to 0 for ci runs
  # we do not want to create any of these policies during a ci run since we're using the same nonprod account
  ci_multiplier = "${var.env_prefix == "ci" ? 0 : 1}"
}

module "client-services-role" {
  source                           = "git::https://github.optum.com/CommercialCloud-EAC/aws_iam.git//modules/iam-role?ref=v2.0.0"
  name                             = "AWS_${local.aws_account_id}_ClientServices"
  description                      = "A role used to provide required access for OPA Client Services"
  assume_role_federated_principals = ["arn:aws:iam::${local.aws_account_id}:saml-provider/UHG_AWS_FEDERATION"]
}

module "content-developer-role" {
  source                           = "git::https://github.optum.com/CommercialCloud-EAC/aws_iam.git//modules/iam-role?ref=v2.0.0"
  name                             = "AWS_${local.aws_account_id}_ContentDevelopers"
  description                      = "A role used to provide required access for OPA Content Developers"
  assume_role_federated_principals = ["arn:aws:iam::${local.aws_account_id}:saml-provider/UHG_AWS_FEDERATION"]
}

# TODO: Ideally we would like to define policy documents once and be able to pick multiple documents 
# for a policy. This is currently not possible but may get resolved in future.
# See: https://github.com/terraform-providers/terraform-provider-aws/issues/5047
data "aws_iam_policy_document" "content-developer-core-policy-doc" {
  statement {
    sid    = "AllowListBuckets"
    effect = "Allow"

    actions = [
      "s3:ListAllMyBuckets",
      "s3:HeadBucket",
    ]

    resources = ["*"]
  }

  statement {
    sid     = "AllowConditionalRedshiftAccess"
    effect  = "Allow"
    actions = ["Redshift:GetClusterCredentials"]

    # allow access to any DB where user has account
    resources = [
      "arn:aws:redshift:*:*:dbuser:*/&{redshift:DbUser}",
      "arn:aws:redshift:*:*:cluster:*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:userid"
      values   = ["${module.content-developer-role.id}:&{redshift:DbUser}@optum.com"]
    }
  }
}

resource "aws_iam_policy" "content-developer-core-policy" {
  name   = "content_dev_core_policy"
  count  = "${1 * local.ci_multiplier}"
  policy = "${data.aws_iam_policy_document.content-developer-core-policy-doc.json}"
}

resource "aws_iam_role_policy_attachment" "content-developer-core-policy-attachment" {
  count      = "${1 * local.ci_multiplier}"
  role       = "${module.content-developer-role.name}"
  policy_arn = "${aws_iam_policy.content-developer-core-policy.arn}"
}

data "aws_iam_policy_document" "client-services-core-policy-doc" {
  statement {
    sid    = "AllowListBuckets"
    effect = "Allow"

    actions = [
      "s3:ListAllMyBuckets",
      "s3:HeadBucket",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "client-services-core-policy" {
  name   = "client_services_core_policy"
  count  = "${1 * local.ci_multiplier}"
  policy = "${data.aws_iam_policy_document.client-services-core-policy-doc.json}"
}

resource "aws_iam_role_policy_attachment" "client-services-core-policy-attachment" {
  count      = "${1 * local.ci_multiplier}"
  role       = "${module.client-services-role.name}"
  policy_arn = "${aws_iam_policy.client-services-core-policy.arn}"
}

module "data-load-role" {
  source                           = "git::https://github.optum.com/CommercialCloud-EAC/aws_iam.git//modules/iam-role?ref=v2.0.0"
  name                             = "AWS_${local.aws_account_id}_DataLoadService"
  description                      = "A role used to perform data loads for OPA"
  assume_role_federated_principals = ["arn:aws:iam::${local.aws_account_id}:saml-provider/UHG_AWS_FEDERATION"]
}

module "link-service-role" {
  source                           = "git::https://github.optum.com/CommercialCloud-EAC/aws_iam.git//modules/iam-role?ref=v2.0.0"
  name                             = "AWS_${local.aws_account_id}_LinkService"
  description                      = "A role used by LINK to access OPA resources"
  assume_role_federated_principals = ["arn:aws:iam::${local.aws_account_id}:saml-provider/UHG_AWS_FEDERATION"]
}

resource "aws_iam_role_policy_attachment" "role-ssm-managed-policy" {
  count      = "${1 * local.ci_multiplier}"
  role       = "AWS_${local.aws_account_id}_Users"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "appstream_user_streaming" {
  count      = "${1 * local.ci_multiplier}"
  role       = "AWS_${local.aws_account_id}_Users"
  policy_arn = "${module.appstream.appstream_streaming_policy}"

  depends_on = ["module.appstream"]
}

resource "aws_iam_role_policy_attachment" "appstream_contentdev_streaming" {
  count      = "${1 * local.ci_multiplier}"
  role       = "${module.content-developer-role.name}"
  policy_arn = "${module.appstream.appstream_streaming_policy}"

  depends_on = ["module.appstream", "module.content-developer-role"]
}

resource "aws_iam_role_policy_attachment" "role-s3-managed-policy" {
  count      = "${local.nonprod_count * local.ci_multiplier}"
  role       = "AWS_${local.aws_account_id}_Users"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "role-codedeploy-managed-policy" {
  count      = "${local.nonprod_count * local.ci_multiplier}"
  role       = "AWS_${local.aws_account_id}_Users"
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
}

resource "aws_iam_role_policy_attachment" "role-codebuild-managed-policy" {
  count      = "${local.nonprod_count * local.ci_multiplier}"
  role       = "AWS_${local.aws_account_id}_Users"
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}

resource "aws_iam_role_policy_attachment" "role-efs-managed-policy" {
  count      = "${local.nonprod_count * local.ci_multiplier}"
  role       = "AWS_${local.aws_account_id}_Users"
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
}

data "aws_iam_policy_document" "pass_role_users_document" {
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current_identity.account_id}:role/*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "execute-api:Invoke",
      "apigateway:GET",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "pass_role_users" {
  count  = "${local.nonprod_count * local.ci_multiplier}"
  policy = "${data.aws_iam_policy_document.pass_role_users_document.json}"
}

resource "aws_iam_role_policy_attachment" "pass_role_users_policy" {
  count      = "${local.nonprod_count * local.ci_multiplier}"
  role       = "AWS_${local.aws_account_id}_Users"
  policy_arn = "${aws_iam_policy.pass_role_users.arn}"
}

data "aws_iam_policy_document" "deny-tf-runner-lambda-access-policy-doc" {
  statement {
    sid       = "DenyTfRunnerAccessForNonAdmins"
    effect    = "Deny"
    actions   = ["lambda:*"]
    resources = ["arn:aws:lambda:*:*:function:*tf-runner*"]
  }
}

resource "aws_iam_policy" "deny-tf-runner-lambda-access-policy" {
  policy = "${data.aws_iam_policy_document.deny-tf-runner-lambda-access-policy-doc.json}"
}

resource "aws_iam_role_policy_attachment" "deny-tf-runner-lambda-access-policy-attachment" {
  role       = "AWS_${local.aws_account_id}_Users"
  policy_arn = "${aws_iam_policy.deny-tf-runner-lambda-access-policy.arn}"
}

resource "aws_iam_service_linked_role" "ssm" {
  # ARN: "arn:aws:iam::${local.account_id}:role/aws-service-role/ssm.amazonaws.com/AWSServiceRoleForAmazonSSM"
  aws_service_name = "ssm.amazonaws.com"
}
