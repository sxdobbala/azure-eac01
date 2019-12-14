locals {
  archive_filename = "${data.external.pip_downloader.result.archive_filename}"
  archive_md5      = "${data.archive_file.source_code_archive.output_md5}"
}

data "external" "pip_downloader" {
  program     = ["sh", "${path.module}/pip_downloader.sh"]
  working_dir = "${path.module}"
}

data "archive_file" "source_code_archive" {
  type        = "zip"
  source_dir  = "${path.module}/src/"
  output_path = "${path.module}/archive/${local.archive_filename}.zip"
}

resource "aws_s3_bucket_object" "source_code_archive_upload" {
  bucket = "${var.s3_artifacts_id}"
  key    = "${var.env_prefix}/opa.api/${local.archive_filename}_${local.archive_md5}.zip"
  source = "${data.archive_file.source_code_archive.output_path}"
  etag   = "${local.archive_md5}"
}

data "archive_file" "source_code_mstr_archive" {
  type        = "zip"
  source_dir  = "${path.module}/src-mstr/"
  output_path = "${path.module}/archive/${local.archive_filename}_mstr.zip"
}

resource "aws_s3_bucket_object" "source_code_mstr_archive_upload" {
  bucket = "${var.s3_artifacts_id}"
  key    = "${var.env_prefix}/opa.api/${local.archive_filename}_mstr.zip"
  source = "${data.archive_file.source_code_mstr_archive.output_path}"
  etag   = "${local.archive_md5}"
}
