locals {
  opa_suffix                           = "${var.is_prod == "true" ? "" : "-opa"}"
  artifacts_bucket_name_suffix         = "${var.artifacts_bucket_name_suffix}${local.opa_suffix}"
  client_data_bucket_name_suffix       = "${var.client_data_bucket_name_suffix}"
  registry_data_bucket_name_suffix     = "${var.registry_data_bucket_name_suffix}"
  flat_files_bucket_name_suffix        = "${var.flat_files_bucket_name_suffix}"
  opa_configuration_bucket_name_suffix = "${var.opa_configuration_bucket_name_suffix}"
  s3_mstr_backups_bucket_name_suffix   = "${var.s3_mstr_backups_bucket_name_suffix}"

  logs_prefix             = "*/AWSLogs/${local.aws_account_id}"
  logs_bucket_name_suffix = "logs${local.opa_suffix}"
  ci_force_destroy        = "${var.env_prefix == "ci" ? true : false}"
  ci_prefix               = "${var.env_prefix == "ci" ? "ci-" : ""}"
}

module "s3-opa-logs" {
  source                   = "git::https://github.optum.com/CommercialCloud-EAC/aws_s3.git//modules/log?ref=v2.1.2"
  name_suffix              = "${local.ci_prefix}logs"
  custom_policy            = "${data.aws_iam_policy_document.logs_custom_policy.json}"
  force_destroy            = "${local.ci_force_destroy}"
  log_bucket_force_destroy = "${local.ci_force_destroy}"
  sse_algorithm            = "aes256"
  versioning_enabled       = false

  tags = "${merge(var.global_tags, map("Name", format("opa_consolidated_%s", var.tag_name_identifier)))}"
}

data "aws_iam_policy_document" "logs_custom_policy" {
  statement {
    actions = ["s3:PutObject"]
    effect  = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["127311923021"]
    }

    # TODO: this should be updated to come from module output (even if we have to fork the aws_s3 module)
    resources = ["arn:aws:s3:::${local.aws_account_id}-${local.ci_prefix}logs/${local.logs_prefix}/*"]
  }
}

module "secure-buckets" {
  source                        = "../secure-buckets"
  is_prod                       = "${var.is_prod}"
  env_prefix                    = "${var.env_prefix}"
  opa_api_source_code_s3_bucket = "${module.opa-api.opa_api_source_code_s3_bucket}"
  opa_api_source_code_s3_key    = "${module.opa-api.opa_api_source_code_s3_key}"
  global_tags                   = "${var.global_tags}"
}
