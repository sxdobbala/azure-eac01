locals {
  # we can't use the flat-files bucket ARN in policies because of circular dependency so construct the ARN from scratch
  s3_flat_files_arn = "arn:aws:s3:::${local.aws_account_id}-${local.ci_prefix}${local.flat_files_bucket_name_suffix}"

  s3_flat_files_permitted_default_users = [
    # account id of current identity
    "${local.aws_account_id}",

    # role id (AROAID) for Admins role
    # Important: DO NOT REMOVE, otherwise bucket will become inaccessible to Admins
    "${data.aws_iam_role.admins_role.unique_id}:*",

    # role id (AROAID) for Service role
    # Important: DO NOT REMOVE, otherwise bucket will become inaccessible to Jenkins
    "${data.aws_iam_role.service_role.unique_id}:*",

    # role id (AROAID) for MSTR ec2 role
    "${data.aws_iam_role.mstr_ec2_role.unique_id}:*",

    # role id (AROAID) for Content Developers role
    "${module.content-developer-role.id}:*",

    # role id (AROAID) for Client Services role
    "${module.client-services-role.id}:*",
  ]

  # Add _Users role to permitted users on non-prod
  s3_flat_files_extra_user = ["${var.is_prod == "true" ? "" : "${data.aws_iam_role.users_role.unique_id}:*"}"]

  s3_flat_files_permitted_users = "${concat(local.s3_flat_files_permitted_default_users,local.s3_flat_files_extra_user)}"
}

module "s3-opa-flat-files" {
  source = "git::https://github.optum.com/oaccoe/aws_s3.git//modules/log"

  name_suffix              = "${local.ci_prefix}${local.flat_files_bucket_name_suffix}"
  log_bucket_name_suffix   = "${local.ci_prefix}${local.logs_bucket_name_suffix}"
  force_destroy            = "${local.ci_force_destroy}"
  log_bucket_force_destroy = "${local.ci_force_destroy}"
  sse_algorithm            = "aes256"
  has_custom_policy        = "true"
  custom_policy            = "${data.aws_iam_policy_document.s3-opa-flat-files-policy-doc.json}"
  versioning_enabled       = false
  tags                     = "${merge(var.global_tags, map("Name", format("opa_consolidated_%s", var.tag_name_identifier)))}"

  global_roles = {
    global_read_only    = ["${module.content-developer-role.name}", "${module.client-services-role.name}"]
    global_read_write   = ["${data.aws_iam_role.mstr_ec2_role.name}"]
    global_full_control = []
  }
}

data "aws_iam_policy_document" "s3-opa-flat-files-policy-doc" {
  # grant write access to MSTR Instance Profile Role
  statement {
    sid    = "AllowWriteAccessOfS3ToMSTRInstanceProfileRole"
    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    principals {
      type        = "AWS"
      identifiers = ["${data.aws_iam_role.mstr_ec2_role.arn}"]
    }

    resources = ["${local.s3_flat_files_arn}/*"]
  }

  # grant read access to ContentDevelopers and ClientServices
  statement {
    sid    = "AllowReadToContentDevAndClientServices"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    principals {
      type        = "AWS"
      identifiers = ["${module.content-developer-role.arn}", "${module.client-services-role.arn}"]
    }

    resources = ["${local.s3_flat_files_arn}", "${local.s3_flat_files_arn}/*"]
  }

  # Whitelist access to only specific accounts and IAM roles using the approach outlined:
  # https://aws.amazon.com/blogs/security/how-to-restrict-amazon-s3-bucket-access-to-a-specific-iam-role/
  statement {
    sid     = "DenyAccessUnlessWhitelistedAccountOrRole"
    effect  = "Deny"
    actions = ["s3:*"]

    principals = {
      type        = "*"
      identifiers = ["*"]
    }

    resources = ["${local.s3_flat_files_arn}", "${local.s3_flat_files_arn}/*"]

    condition {
      # anything that doesn't match the list of accounts or roles below will be denied
      test     = "StringNotLike"
      variable = "aws:userId"

      values = ["${local.s3_flat_files_permitted_users}"]
    }
  }
}
