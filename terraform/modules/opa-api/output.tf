output "opa_api_source_code" {
  value = "${data.archive_file.source_code_archive.output_path}"
}

output "opa_api_source_code_s3_bucket" {
  value = "${aws_s3_bucket_object.source_code_archive_upload.bucket}"
}

output "opa_api_source_code_s3_key" {
  value = "${aws_s3_bucket_object.source_code_archive_upload.key}"
}
