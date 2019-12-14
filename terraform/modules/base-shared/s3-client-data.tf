locals {
  # we can't use the client-data bucket ARN in policies because of circular dependency so construct the ARN from scratch
  s3_client_data_arn = "arn:aws:s3:::${local.aws_account_id}-${local.ci_prefix}${local.client_data_bucket_name_suffix}"
}

# intentionally not using replication so we can avoid versioning 
# need ability to hard delete data for dropped clients
module "s3-opa-client-data" {
  source = "git::https://github.optum.com/oaccoe/aws_s3.git//modules/log"

  name_suffix              = "${local.ci_prefix}${local.client_data_bucket_name_suffix}"
  log_bucket_name_suffix   = "${local.ci_prefix}${local.logs_bucket_name_suffix}"
  force_destroy            = "${local.ci_force_destroy}"
  log_bucket_force_destroy = "${local.ci_force_destroy}"
  sse_algorithm            = "aes256"
  has_custom_policy        = "true"
  custom_policy            = "${data.aws_iam_policy_document.s3-opa-client-data-policy-doc.json}"
  versioning_enabled       = false
  tags                     = "${merge(var.global_tags, map("Name", format("opa_consolidated_%s", var.tag_name_identifier)))}"

  global_roles = {
    global_read_only    = []
    global_read_write   = ["${module.data-load-role.name}"]
    global_full_control = []
  }
}

data "aws_iam_policy_document" "s3-opa-client-data-policy-doc" {
  # grant full read access to Redshift service role
  statement {
    sid     = "AllowReadAccessToRedshiftServiceRole"
    effect  = "Allow"
    actions = ["s3:Get*", "s3:List*"]

    principals {
      type        = "AWS"
      identifiers = ["${module.redshift-service-access-role.arn}"]
    }

    resources = ["${local.s3_client_data_arn}", "${local.s3_client_data_arn}/*"]
  }

  # grant read/write access to DataLoadService role
  statement {
    sid    = "AllowWriteAccessToDataLoadServiceRole"
    effect = "Allow"

    # TODO: find out if these permissions can be tightened up further
    actions = [
      "s3:PutObject",
    ]

    principals {
      type        = "AWS"
      identifiers = ["${module.data-load-role.arn}"]
    }

    resources = ["${local.s3_client_data_arn}/*"]
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

    resources = ["${local.s3_client_data_arn}", "${local.s3_client_data_arn}/*"]

    condition {
      # anything that doesn't match the list of accounts or roles below will be denied
      test     = "StringNotLike"
      variable = "aws:userId"

      values = [
        # account id of current identity
        "${local.aws_account_id}",

        # role id (AROAID) for Admins role
        # Important: DO NOT REMOVE, otherwise bucket will become inaccessible to Admins
        "${data.aws_iam_role.admins_role.unique_id}:*",

        # role id (AROAID) for Service role
        # Important: DO NOT REMOVE, otherwise bucket will become inaccessible to Jenkins
        "${data.aws_iam_role.service_role.unique_id}:*",

        # role id (AROAID) for Redshift service role
        "${module.redshift-service-access-role.id}:*",

        # role id (AROAID) for DataLoadService role
        "${module.data-load-role.id}:*",
      ]
    }
  }

  # NOTE: We're restricting access via accounts and IAM roles above so there is likely no need to apply VPC-based restrictions.
  # NOTE: Leaving this in for reference during the code review process.

  # # Deny all access to the client data bucket outside the VPC
  # statement {
  #   sid        = "DenyAccessOutsideVPC"
  #   effect     = "Deny"
  #   actions    = ["s3:*"]
  #   principals = ["*"]
  #   resources  = ["${local.s3_client_data_arn}/*"]

  #   condition {
  #     test     = "StringNotLike"
  #     variable = "aws:sourceVpc"

  #     values = [
  #       "${module.network.vpc_id}",
  #     ]
  #   }
  # }
}
