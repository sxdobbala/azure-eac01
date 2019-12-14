output "opa_mstr_aws_archive_s3_key" {
  description = "S3 key under which the opa-mstr-aws archive is stored"
  value       = "${aws_s3_bucket_object.opa-mstr-aws-upload.id}"
}
