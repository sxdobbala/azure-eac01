resource "aws_cloudwatch_log_group" "session_manager_log_group" {
  name = "${var.cloudwatch_log_group_name}"
  tags = "${var.global_tags}"
}

resource "null_resource" "session_manager_prefs_provisioner" {
  provisioner "local-exec" {
    command     = "python3 '${path.module}/ssm_prefs.py' --s3_bucket_name '${var.s3_bucket_name}' --s3_key_prefix '${var.s3_key_prefix}' --cloudwatch_log_group_name '${var.cloudwatch_log_group_name}'"
    on_failure  = "fail"
    interpreter = ["bash", "-c"]
  }

  depends_on = ["aws_cloudwatch_log_group.session_manager_log_group"]
}
