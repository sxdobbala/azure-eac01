# Updates to the MSTR Cloudformation scripts to make them work for us.

## Main things updated
1) Updates the global cloudformation stack (MicroStrategyOnAWS) and locks down security groups
2) Use a version of BuildCloudFormationParameters given to us by MSTR that skips the installation of unnecessary packages
3) Now using the new MSTR Macro feature as opposed to preprocessing https://community.microstrategy.com/s/article/MicroStrategy-On-AWS-Encryption?language=en_US
    1) Updates security groups to lock then down more
    2) Removes usher from the deployment (which breaks with the lock down from #1)
    3) Pulls our custom packer AMI our list by source_ami tag
    4) Adds extra ssl and monitoring not originally provided.

**Please note that this is a global configuration per account, so it can really only be used once per account.   The lambda that MSTR provide have hard coded names.**## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| appstream\_sg\_id | ID for AppStream SG created in appstream module | string | n/a | yes |
| artifacts\_s3\_bucket | OPA artifacts bucket | string | n/a | yes |
| env\_prefix | Unique environment prefix to identify resources for an environment, e.g. dev/qa/state/prod or dev-joe | string | `""` | no |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| ingress\_cidr\_block | Classless Inter-Domain Routing (CIDR) block for the NACL | string | n/a | yes |
| is\_prod | Flag used to determine whether to create prod or non-prod resources | string | n/a | yes |
| mstr\_aws\_cloudformation\_stack\_template\_url | Template URL for MicroStrategyOnAWS cloud formation stack | string | `"https://s3.amazonaws.com/securecloud-config-prod-us-east-1/cloudformations/MSTRonAWSOrchestration-customer-prod.json"` | no |
| privatesubnet01 | Classless Inter-Domain Routing (CIDR) block for the NACL | string | n/a | yes |
| privatesubnet02 | Classless Inter-Domain Routing (CIDR) block for the NACL | string | n/a | yes |
| publicsubnet01 | Classless Inter-Domain Routing (CIDR) block for the NACL | string | n/a | yes |
| publicsubnet02 | Classless Inter-Domain Routing (CIDR) block for the NACL | string | n/a | yes |
| vpc | Classless Inter-Domain Routing (CIDR) block for the VPC | string | n/a | yes |
| vpc\_cidr\_block | Classless Inter-Domain Routing (CIDR) block for the VPC | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| mstr\_stack\_name |  |
| orchestration\_arn |  |

