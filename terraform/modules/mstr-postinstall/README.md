## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| artifacts\_s3\_bucket | The bucket where OPA artifacts will be uploaded | string | n/a | yes |
| aws\_region | aws region to create resources | string | n/a | yes |
| dataloader\_egress\_sg\_id | Dataloader egress Security group Id | string | n/a | yes |
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe | string | `""` | no |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| opa\_api\_source\_code\_s3\_bucket | S3 bucket with API lambda source code | string | n/a | yes |
| opa\_api\_source\_code\_s3\_key | S3 key with API lambda source code | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| opa\_mstr\_postinstall\_lambda\_arn |  |

