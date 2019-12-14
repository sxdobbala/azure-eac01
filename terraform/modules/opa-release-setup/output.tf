output "opa_release_sns_topic_arn" {
  description = "OPA release step function SNS topic arn"
  value       = "${aws_sns_topic.opa-release-setup-sns-topic.arn}"
}

output "opa_release_sns_role_arn" {
  description = "OPA release step function SNS topic role arn"
  value       = "${aws_iam_role.opa-release-setup-sns-role.arn}"
}
