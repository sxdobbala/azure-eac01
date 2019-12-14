output "appstream_sg_id" {
  value = "${aws_security_group.appstream_sg.id}"
}

output "appstream_streaming_policy" {
  value = "${aws_iam_policy.allow_user_streaming_policy.arn}"
}
