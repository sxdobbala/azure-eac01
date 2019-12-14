locals {
  # we can't use the registry-data bucket ARN in policies because of circular dependency so construct the ARN from scratch
  s3_registry_data_arn = "arn:aws:s3:::${local.aws_account_id}-${local.ci_prefix}${local.registry_data_bucket_name_suffix}"
}

module "s3-opa-registry-data" {
  source = "git::https://github.optum.com/oaccoe/aws_s3.git//modules/log"

  name_suffix              = "${local.ci_prefix}${local.registry_data_bucket_name_suffix}"
  log_bucket_name_suffix   = "${local.ci_prefix}${local.logs_bucket_name_suffix}"
  force_destroy            = "${local.ci_force_destroy}"
  log_bucket_force_destroy = "${local.ci_force_destroy}"
  sse_algorithm            = "aes256"
  has_custom_policy        = "true"
  custom_policy            = "${data.aws_iam_policy_document.s3-opa-registry-data-policy-doc.json}"
  versioning_enabled       = false
  tags                     = "${merge(var.global_tags, map("Name", format("opa_consolidated_%s", var.tag_name_identifier)))}"
}

data "aws_iam_policy_document" "s3-opa-registry-data-policy-doc" {
  # Needed by "link-integration" module...
  # grant read access to LINK service role to the folder where registry data will be stored
  statement {
    sid     = "AllowReadAccessToLinkServiceRole"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    principals {
      type = "AWS"

      identifiers = [
        # OPA's own role for LINK
        "${module.link-service-role.arn}",
      ]
    }

    resources = ["${local.s3_registry_data_arn}/${var.link_s3_prefix}/*"]
  }
}
