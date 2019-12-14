output "client_onboarding_sfn_arn" {
  value = "${aws_sfn_state_machine.client-onboarding-sfn.id}"
}

output "client_stack_rotation_sfn_arn" {
  value = "${aws_sfn_state_machine.client-stack-rotation-sfn.id}"
}
