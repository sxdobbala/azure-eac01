# Basic VPC with NACL's, plus a data subnet for running databases## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_azs | Availability Zones to create VPC | list | n/a | yes |
| aws\_region | aws region to create resources | string | n/a | yes |
| az\_count | Number of AZs | string | n/a | yes |
| data\_subnets\_cidr\_blocks | CIDR Blocks for Data Subnet | list | n/a | yes |
| dataports | List of ports needed for data NACL | list | n/a | yes |
| dataports\_count | Number of ports needed for data NACL | string | n/a | yes |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| is\_hybrid | Hybrid network conditional flag - set to true to turn on hybrid connectivity | string | `"false"` | no |
| network\_name | Name for the Network | string | n/a | yes |
| new\_private\_subnets\_cidr\_blocks | CIDR blocks for the new private subnets | list | n/a | yes |
| private\_subnets\_cidr\_blocks | CIDR Blocks for Private Subnet | list | n/a | yes |
| public\_subnets\_cidr\_blocks | CIDR Blocks for Private Subnet | list | n/a | yes |
| virtual\_interface\_id | ID of Direct Connect Virtual Interface | string | `""` | no |
| vpc\_cidr\_block | Classless Inter-Domain Routing (CIDR) block for the VPC | string | n/a | yes |
| vpc\_secondary\_cidr\_blocks | Additional CIDR blocks for VPC | list | `<list>` | no |

## Outputs

| Name | Description |
|------|-------------|
| api\_gateway\_vpce\_sg\_id | Security group ID for the VPC endpoint granting access to the OPA API |
| hybrid\_subnet\_cidr\_blocks |  |
| subnet\_data\_nacl\_id |  |
| subnet\_data\_route\_table |  |
| subnet\_data\_subnet\_cidr\_blocks |  |
| subnet\_data\_subnet\_ids |  |
| subnet\_new\_private\_subnet\_cidr\_blocks |  |
| subnet\_new\_private\_subnet\_ids | if no new private subnets specified, return the original private subnet |
| vpc\_cidr\_block |  |
| vpc\_id |  |
| vpc\_nat\_gateway |  |
| vpc\_private\_nacl\_id |  |
| vpc\_private\_route\_table |  |
| vpc\_private\_sg\_id |  |
| vpc\_private\_subnet\_ids |  |
| vpc\_public\_route\_table |  |
| vpc\_public\_sg\_id |  |
| vpc\_public\_subnet\_ids |  |
| vpc\_s3\_endpoint |  |
| vpc\_s3\_endpoint\_cidr\_blocks |  |

