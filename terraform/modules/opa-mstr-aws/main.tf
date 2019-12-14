locals {
  archive_filename = "${var.env_prefix}-opa-mstr-aws.zip"
}

data "archive_file" "opa-mstr-aws-archive" {
  type        = "zip"
  source_dir  = "${path.module}/provision/"
  output_path = "${path.module}/archive/${local.archive_filename}"
}

resource "aws_s3_bucket_object" "opa-mstr-aws-upload" {
  bucket = "${var.s3_artifacts_id}"
  key    = "terraform/${local.archive_filename}"
  source = "${data.archive_file.opa-mstr-aws-archive.output_path}"
  etag   = "${filemd5("${data.archive_file.opa-mstr-aws-archive.output_path}")}"
}
