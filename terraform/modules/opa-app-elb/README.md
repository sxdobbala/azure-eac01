## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_region | aws region to create resources | string | n/a | yes |
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/stg/prod or dev-joe | string | `""` | no |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| orchestration\_arn | The ARN of the SNS Orchestrator topic created by the MSTR CloudFormation stack | string | n/a | yes |
| s3\_opa\_logs\_id | OPA logs S3 bucket id | string | n/a | yes |
| ssl\_cert\_name | Name of the SSL certificate. e.g. devcloud/qacloud | string | n/a | yes |
| vpc\_id | VPC id | string | n/a | yes |
| vpc\_public\_subnet\_ids | VPC public subnet ids | list | n/a | yes |

