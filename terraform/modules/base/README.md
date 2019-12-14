## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| alarm\_thresholds | Threshold values for the various critical alarms | map | `<map>` | no |
| alarms\_email | Triggered alarms will be notified to this email address | string | n/a | yes |
| api\_id | ID of the API | string | n/a | yes |
| aws\_region | AWS region to create resources | string | n/a | yes |
| aws\_replication\_region | AWS region for replication | string | n/a | yes |
| ca\_private\_key\_ssm\_param\_name | SSM param name for CA private key | string | n/a | yes |
| ca\_public\_cert\_ssm\_param\_name | SSM param name for CA public cert | string | n/a | yes |
| data\_load\_service\_role\_name | The name of the Data Load Service role | string | n/a | yes |
| dataloader\_autoscale\_max | Choose the maximum instances to be used by load balancer | string | `"1"` | no |
| dataloader\_autoscale\_min | Choose the minimum instances to be used by load balancer | string | `"1"` | no |
| dataloader\_ec2\_instance\_type | The instance type used to run the application | string | `"t2.micro"` | no |
| dataloader\_s3\_bucket\_id | Id of the S3 bucket used for temp storage | string | n/a | yes |
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe | string | n/a | yes |
| global\_tags | Global tags to be applied to all resources | map | n/a | yes |
| hybrid\_subnet\_cidr\_blocks | CIDR blocks for the hybrid subnets of the VPC | list | n/a | yes |
| is\_prod | Flag used to determine whether to create prod or non-prod resources | string | n/a | yes |
| link\_service\_role\_arn | ARN of the role the LINK team is using to send/receive SQS messages | string | n/a | yes |
| mstr\_rds\_instance\_class | Target instance class when resizing the RDS mySQL instances created by MSTR. | string | n/a | yes |
| opa\_release\_s3\_bucket | S3 artifacts bucket contains opa-releases package | string | n/a | yes |
| orchestration\_arn | ARN for the SNS topic used by MSTR to orchestrate | string | n/a | yes |
| s3\_artifacts\_id | S3 bucket for OPA artifacts | string | n/a | yes |
| s3\_client\_data\_id | S3 bucket for OPA client data | string | n/a | yes |
| s3\_mstr\_backups\_id | S3 bucket for opa-mstr-backups | string | n/a | yes |
| s3\_opa\_logs\_id | S3 bucket for OPA logs | string | n/a | yes |
| s3\_registry\_data\_id | S3 bucket for OPA registry data | string | n/a | yes |
| ssl\_cert\_name | Name of the SSL certificate to install on the MSTR load balancer | string | `"wildcardTrialCloud2020"` | no |
| subnet\_data\_subnet\_cidr\_blocks | CIDR blocks for the data subnets of the VPC | list | n/a | yes |
| subnet\_data\_subnet\_ids | IDs for the data subnets of the VPC | list | n/a | yes |
| subnet\_new\_private\_subnet\_cidr\_blocks | CIDR blocks for the  new private subnets of the VPC | list | n/a | yes |
| subnet\_new\_private\_subnet\_ids | IDs for the new private subnets of the VPC | list | n/a | yes |
| vpc\_cidr\_block | CIDR block for the VPC | string | n/a | yes |
| vpc\_id | ID of the VPC | string | n/a | yes |
| vpc\_private\_subnet\_ids | IDs for the private subnets of the VPC | list | n/a | yes |
| vpc\_public\_subnet\_ids | IDs for the public subnets of the VPC | list | n/a | yes |
| vpc\_s3\_endpoint\_cidr\_blocks | CIDR blocks for the S3 endpoint of the VPC | list | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| opa\_release\_sns\_topic\_arn |  |
| redshift\_egress\_sg\_id |  |

