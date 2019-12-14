## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| artifacts\_bucket\_name\_suffix | Suffix for artifacts S3 bucket | string | n/a | yes |
| assessment\_target\_name | The name of the assessment target | string | `"OPA"` | no |
| aws\_profile | aws credential profile | string | n/a | yes |
| aws\_region | aws region to create resources | string | n/a | yes |
| aws\_replication\_region | Region for replication | string | n/a | yes |
| client\_data\_bucket\_name\_suffix | Suffix for client data S3 bucket | string | n/a | yes |
| data\_subnets\_cidr\_blocks | CIDR blocks for the data subnets | list | n/a | yes |
| dataports | The ports for the data network | list | n/a | yes |
| dataports\_count | The number of ports for the data network | string | n/a | yes |
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe | string | n/a | yes |
| flat\_files\_bucket\_name\_suffix | Suffix for flat files S3 bucket | string | n/a | yes |
| global\_tags | Global tags to apply to all resources in module | map | `<map>` | no |
| is\_hybrid\_network | Set to 'true' to add hybrid connectivity to the network. | string | n/a | yes |
| is\_prod | Flag used to determine whether to create prod or non-prod resources | string | n/a | yes |
| link\_s3\_prefix | Folder prefix for storage of LINK registry data in S3 | string | `"link-data"` | no |
| network\_name | Name of the network to create | string | n/a | yes |
| new\_private\_subnets\_cidr\_blocks | CIDR blocks for the new private subnets | list | `<list>` | no |
| opa\_configuration\_bucket\_name\_suffix | Suffix for opa configuration S3 bucket | string | n/a | yes |
| private\_subnets\_cidr\_blocks | CIDR blocks for the private subnets | list | n/a | yes |
| public\_subnets\_cidr\_blocks | CIDR blocks for the public subnets | list | n/a | yes |
| registry\_data\_bucket\_name\_suffix | Suffix for registry data S3 bucket | string | n/a | yes |
| s3\_mstr\_backups\_bucket\_name\_suffix | Suffix for opa-mstr-backups S3 bucket | string | n/a | yes |
| tag\_name\_identifier | tag name identifier for the aws_base | string | n/a | yes |
| tag\_value\_for\_instances | Tag value to identify and group the EC2 instances to run the assessment. Key used here is aws_inspector, Value can be true or false | string | `"true"` | no |
| virtual\_interface\_id | ID of Direct Connect Virtual Interface | string | `""` | no |
| vpc\_cidr\_block | CIDR block for use by the network. | string | n/a | yes |
| vpc\_secondary\_cidr\_blocks | Additional CIDR blocks for use by the network. | list | `<list>` | no |

## Outputs

| Name | Description |
|------|-------------|
| appstream\_sg\_id |  |
| artifacts\_s3\_id |  |
| ca\_private\_key\_ssm\_param\_name | SSM param name for CA private key |
| ca\_public\_cert\_ssm\_param\_name | SSM param name for CA public cert |
| data\_load\_service\_role\_name | Name of the Data Load Service role |
| hybrid\_subnet\_cidr\_blocks |  |
| link\_service\_role\_arn | ARN of role for LINK access to OPA resources |
| orchestration\_arn |  |
| redshift\_service\_access\_role\_arn | ARN of role for Redshift access to other AWS services |
| redshift\_service\_access\_role\_id | ID (so called AROAID) of role for Redshift access to other AWS services |
| s3\_client\_data\_id |  |
| s3\_mstr\_backups\_id |  |
| s3\_opa\_logs\_id |  |
| s3\_registry\_data\_id |  |
| subnet\_data\_nacl\_id |  |
| subnet\_data\_route\_table |  |
| subnet\_data\_subnet\_cidr\_blocks |  |
| subnet\_data\_subnet\_ids |  |
| subnet\_new\_private\_subnet\_cidr\_blocks |  |
| subnet\_new\_private\_subnet\_ids |  |
| vpc\_cidr\_block |  |
| vpc\_id |  |
| vpc\_private\_route\_table |  |
| vpc\_private\_sg\_id |  |
| vpc\_private\_subnet\_ids |  |
| vpc\_public\_route\_table |  |
| vpc\_public\_sg\_id |  |
| vpc\_public\_subnet\_ids |  |
| vpc\_s3\_endpoint |  |
| vpc\_s3\_endpoint\_cidr\_blocks |  |

