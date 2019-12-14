output "deploy_opa_lambda_arn" {
  description = "deploy_opa lambda arn"
  value       = "${module.lambda_deploy_opa.arn}"
}
