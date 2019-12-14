output "http_method" {
  value = "${aws_api_gateway_integration_response.response_method_integration.http_method}"
}

output "api_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}"
}

output "function_name" {
  value = "${module.api_lambda.function_name}"
}

output "arn" {
  value = "${module.api_lambda.arn}"
}

output "qualified_arn" {
  value = "${module.api_lambda.qualified_arn}"
}

output "invoke_arn" {
  value = "${module.api_lambda.invoke_arn}"
}

output "role_name" {
  value = "${module.api_lambda.role_name}"
}

output "role_arn" {
  value = "${module.api_lambda.role_arn}"
}

output "version" {
  value = "${module.api_lambda.version}"
}

output "source_code_hash" {
  value = "${module.api_lambda.source_code_hash}"
}