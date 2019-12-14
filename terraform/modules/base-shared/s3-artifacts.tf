locals {
  # we can't use the artifacts bucket ARN in policies because of circular dependency so construct the ARN from scratch
  s3_artifacts_arn = "arn:aws:s3:::${local.aws_account_id}-${local.ci_prefix}${local.artifacts_bucket_name_suffix}"
}

module "s3-opa-artifacts" {
  source                 = "git::https://github.optum.com/CommercialCloud-EAC/aws_s3.git//modules/rep-log?ref=v2.1.2"
  name_suffix            = "${local.ci_prefix}${local.artifacts_bucket_name_suffix}"
  log_bucket_name_suffix = "${local.ci_prefix}${local.logs_bucket_name_suffix}"
  rep_bucket_name_suffix = "${local.ci_prefix}replication"

  global_roles = {
    global_read_only    = []
    global_read_write   = ["${module.content-developer-role.name}"]
    global_full_control = []
  }

  custom_policy            = "${data.aws_iam_policy_document.s3-opa-artifacts-policy-doc.json}"
  force_destroy            = "${local.ci_force_destroy}"
  log_bucket_force_destroy = "${local.ci_force_destroy}"
  rep_bucket_force_destroy = "${local.ci_force_destroy}"
  sse_algorithm            = "aes256"

  tags = "${merge(var.global_tags, map("Name", format("opa_consolidated_%s", var.tag_name_identifier)))}"
}

data "aws_iam_policy_document" "s3-opa-artifacts-policy-doc" {
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

    resources = ["${local.s3_artifacts_arn}",
      "${local.s3_artifacts_arn}/e2e-releases/*",
      "${local.s3_artifacts_arn}/mavenrepo/*",
    ]
  }

  # grant read/write access to DataLoadService role
  statement {
    sid    = "AllowReadWriteAccessToDataLoadServiceRole"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]

    principals {
      type        = "AWS"
      identifiers = ["${module.data-load-role.arn}"]
    }

    resources = ["${local.s3_artifacts_arn}",
      "${local.s3_artifacts_arn}/dataload-sandbox/*",
    ]
  }
}

resource "aws_ssm_parameter" "artifacts_s3_bucket" {
  name      = "artifacts_s3_bucket"
  type      = "String"
  value     = "${module.s3-opa-artifacts.id}"
  overwrite = true
  tags      = "${var.global_tags}"
}
