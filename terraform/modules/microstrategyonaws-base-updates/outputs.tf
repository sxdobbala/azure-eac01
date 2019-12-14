output "mstr_stack_name" {
  value = "${aws_cloudformation_stack.MicroStrategyOnAWS.name}"
}

output "orchestration_arn" {
  value = "${local.stack_outputs["CloudOrchestratorSNSTopic"]}"
}
