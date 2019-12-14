## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| dataloader\_egress\_sg\_id | Dataloader egress Security group Id | string | n/a | yes |
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe | string | `""` | no |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| hybrid\_cidr\_block | CIDR block for the hybrid network | list | n/a | yes |
| link\_service\_role\_arn | ARN of the role the LINK team is using to send/receive SQS messages | string | n/a | yes |
| opa\_api\_source\_code\_s3\_bucket | S3 bucket with API lambda source code | string | n/a | yes |
| opa\_api\_source\_code\_s3\_key | S3 key with API lambda source code | string | n/a | yes |
| private\_subnet\_ids | VPC private subnet ids | list | n/a | yes |
| registry\_api\_url | The url for the DataLoader registry API | string | n/a | yes |
| s3\_bucket | The bucket where registry data will be uploaded | string | n/a | yes |
| s3\_prefix | The bucket prefix where LINK registry data will be uploaded | string | `"link-data"` | no |
| vpc\_cidr\_block | CIDR block for the VPC | list | n/a | yes |
| vpc\_id | VPC id | string | n/a | yes |

