## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_region | aws region to create resources | string | n/a | yes |
| deploy\_mstr\_lambda\_arn | The arn of opa-mstr-migration lambda | string | n/a | yes |
| deploy\_opa\_lambda\_arn | The arn of deploy_opa lambda | string | n/a | yes |
| opa\_release\_sns\_role\_arn | OPA release step function SNS topic role arn | string | n/a | yes |
| opa\_release\_sns\_topic\_arn | OPA release step function SNS topic arn | string | n/a | yes |
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe | string | n/a | yes |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| s3\_artifacts\_id | S3 bucket for OPA artifacts | string | n/a | yes |
| s3\_prefix | The bucket prefix where stored opa-release packages. | string | `"opa-releases"` | no |

