output "opa_mstr_migration_lambda_arn" {
  value = "${module.api_method_opa_mstr_migration.arn}"
}

output "opa_mstr_stack_lambda_arn" {
  value = "${module.api_method_opa_mstr_stack.arn}"
}

output "opa_tf_runner_lambda_arn" {
  value = "${module.api_method_opa_tf_runner.arn}"
}

output "opa_master_lambda_arn" {
  value = "${module.api_method_opa_master.arn}"
}

output "opa_client_onboarding_lambda_arn" {
  value = "${module.api_method_opa_client_onboarding.arn}"
}

output "opa_deploy_rw_schema_lambda_arn" {
  value = "${module.api_method_opa_deploy_rw_schema.arn}"
}

output "opa_mstr_backup_lambda_arn" {
  value = "${module.api_method_opa_mstr_backup.arn}"
}

output "opa_smoke_test_lambda_arn" {
  value = "${module.api_method_opa_smoke_test.arn}"
}

output "opa_client_env_move_lambda_arn" {
  value = "${module.api_method_opa_client_env_move.arn}"
}

output "opa_client_redshift_security_lambda_arn" {
  value = "${module.api_method_opa_client_redshift_security.arn}"
}

output "opa_timezone_change_lambda_arn" {
  value = "${module.api_method_opa_timezone_change.arn}"
}
