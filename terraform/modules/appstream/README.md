## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| egress\_port\_numbers | List of Port Numbers to Set up Egress On | list | `<list>` | no |
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe | string | `""` | no |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| https\_cidr\_blocks | CIDR Blocks for HTTPS | list | `<list>` | no |
| image\_arn | ARN of appstream image | string | n/a | yes |
| list\_of\_aws\_azs | List of AWS AZ's to run in | list | n/a | yes |
| list\_of\_cidr\_block\_for\_private\_subnets | List of CIDR Blocks for private subnets to run in | list | n/a | yes |
| vpc\_id | ID of VPC | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| appstream\_sg\_id |  |
| appstream\_streaming\_policy |  |

