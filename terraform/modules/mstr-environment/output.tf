output "mstr_environment_create_sfn_arn" {
  value = "${aws_sfn_state_machine.mstr-environment-create-sfn.id}"
}

output "mstr_environment_destroy_sfn_arn" {
  value = "${aws_sfn_state_machine.mstr-environment-destroy-sfn.id}"
}

output "mstr_backup_sfn_arn" {
  value = "${aws_sfn_state_machine.mstr-backup-sfn.id}"
}

output "mstr_stack_create_sfn_arn" {
  value = "${aws_sfn_state_machine.mstr-stack-create-sfn.id}"
}

output "mstr_stack_destroy_sfn_arn" {
  value = "${aws_sfn_state_machine.mstr-stack-destroy-sfn.id}"
}
