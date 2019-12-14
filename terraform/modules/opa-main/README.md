# Contains shared resources for OPA CodeDeploy app## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| artifacts\_s3\_bucket | The bucket where OPA artifacts will be uploaded | string | n/a | yes |
| aws\_region | aws region to create resources | string | n/a | yes |
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe | string | n/a | yes |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| opa\_api\_source\_code\_s3\_bucket | S3 bucket with API lambda source code | string | n/a | yes |
| opa\_api\_source\_code\_s3\_key | S3 key with API lambda source code | string | n/a | yes |
| opa\_release\_s3\_prefix | S3 folder where release packages are stored | string | `"e2e-releases"` | no |

## Outputs

| Name | Description |
|------|-------------|
| deploy\_opa\_lambda\_arn | deploy_opa lambda arn |

