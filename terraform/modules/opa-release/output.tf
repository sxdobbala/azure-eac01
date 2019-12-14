output "opa_release_sfn_arn" {
  value = "${aws_sfn_state_machine.opa-release-sfn.id}"
}
