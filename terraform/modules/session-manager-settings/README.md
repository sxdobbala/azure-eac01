## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| cloudwatch\_log\_group\_name | The name of the log group to upload session logs to. Specifying this enables sending session output to CloudWatch Logs. | string | n/a | yes |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| s3\_bucket\_name | The name of bucket to store session logs. Specifying this enables writing session output to an Amazon S3 bucket. | string | n/a | yes |
| s3\_key\_prefix | To write output to a sub-folder, enter a sub-folder name. | string | n/a | yes |

