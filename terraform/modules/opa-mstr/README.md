# Contains mstr instance specific resources for OPA CodeDeploy app## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe | string | n/a | yes |
| environmentName | MSTR Environment Name | string | n/a | yes |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| mstr\_stack\_name | MSTR instance stack name. e.g env-12345 | string | n/a | yes |
| opa\_release\_sns\_topic\_arn | OPA release SNS topic arn | string | `"null"` | no |

