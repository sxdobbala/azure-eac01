locals {
  # we can't use the opa-mstr-backups bucket ARN in policies because of circular dependency so construct the ARN from scratch
  s3_mstr_backups_arn = "arn:aws:s3:::${local.aws_account_id}-${local.ci_prefix}${local.s3_mstr_backups_bucket_name_suffix}"
}

module "s3-mstr-backups" {
  source = "git::https://github.optum.com/oaccoe/aws_s3.git//modules/simple?ref=v2.2.0"

  name_suffix        = "${local.ci_prefix}${local.s3_mstr_backups_bucket_name_suffix}"
  force_destroy      = "${local.ci_force_destroy}"
  sse_algorithm      = "aes256"
  custom_policy      = "${data.aws_iam_policy_document.s3-mstr-backups-policy-doc.json}"
  versioning_enabled = false
  tags               = "${merge(var.global_tags, map("Name", format("opa_consolidated_%s", var.tag_name_identifier)))}"
}

data "aws_iam_policy_document" "s3-mstr-backups-policy-doc" {
  statement {
    sid     = "AllowReadAccessFromProdAccount"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:ListBucket"]

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::029620356096:root",
      ]
    }

    resources = ["${local.s3_mstr_backups_arn}",
      "${local.s3_mstr_backups_arn}/*",
    ]
  }
}