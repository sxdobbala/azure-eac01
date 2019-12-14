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
```## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe | string | n/a | yes |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| lambda\_arn | ARN of the lambda function to schedule | string | n/a | yes |
| lambda\_name | Name of the lambda function to schedule | string | n/a | yes |
| rule\_name | Name for the scheduled cloudwatch rule | string | `""` | no |
| schedule\_expression | Schedule expression for the cloudwatch rule (in valid cron format) | string | n/a | yes |

