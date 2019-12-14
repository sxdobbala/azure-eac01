# Terraform Module "schedule-lambda-run"

Allows lambda functions to be executed on a schedule.

### Example Usage

```hcl
module "lambda-schedule-run" {
  source = "../schedule-lambda-run"

  env_prefix          = "${var.env_prefix}"
  rule_name           = "schedule-run-${var.function_name}"
  lambda_name         = "${var.function_name}"
  lambda_arn          = "${var.lambda_arn}"
  schedule_expression = "rate(1 hour)"
  global_tags         = "${var.global_tags}"
}
```