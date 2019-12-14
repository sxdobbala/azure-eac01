## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| allocated\_storage | The amount of storage in GB allocated to the database instance | string | `"50"` | no |
| apply\_changes\_immediately | Specifies whether any cluster modifications are applied immediately, or during the next maintenance window | string | `"true"` | no |
| auto\_minor\_version\_upgrade | Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window | string | `"true"` | no |
| aws\_profile | DEPRECATED. AWS Profile is inherited from parent module. | string | `""` | no |
| aws\_region | DEPRECATED. AWS Region is inherited from parent module. | string | `"us-east-1"` | no |
| backup\_retention\_period | The days to retain backups for | string | `"3"` | no |
| backup\_window | Backup window during which automated backups are created if automated backups are enabled using the BackupRetentionPeriod parameter. In UTC | string | `"06:00-08:00"` | no |
| data\_subnet\_ids | VPC data subnet ids | list | n/a | yes |
| database\_identifier | Must be unique for all DB instances per AWS account, per region | string | n/a | yes |
| database\_name | The name of the primary database to create on the instance | string | n/a | yes |
| engine | Database engine to use for the instance | string | n/a | yes |
| engine\_version | Database engine version to use for the instance | string | n/a | yes |
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe | string | n/a | yes |
| event\_subscription\_cluster\_config | Event subscription cluster configuration.When enabled SNS topic is must | map | `<map>` | no |
| event\_subscription\_instances\_config | Event subscription instance configuration.When enabled SNS topic is must | map | `<map>` | no |
| event\_subscription\_parametergroup\_config | Event subscription parametergroup configuration.When enabled SNS topic is must | map | `<map>` | no |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| hybrid\_cidr\_block | CIDR block for the hybrid network | list | n/a | yes |
| iam\_auth\_enabled | Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled | string | `"true"` | no |
| instance\_class | Instance class to use for this instance | string | n/a | yes |
| instance\_port | The port on which the DB accepts connections | string | n/a | yes |
| kms\_key\_id\_arn | The ARN for the KMS encryption key.When None specified, AWS managed key is used for SSE | string | `""` | no |
| maintenance\_window | Weekly time range during which system maintenance can occur, in UTC | string | `"sat:08:00-sat:10:00"` | no |
| master\_username | The name of the primary database to create on the instance | string | n/a | yes |
| monitoring\_interval | The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance | string | `"1"` | no |
| multi\_az | Whether or not the RDS instance support multiple availability zones | string | `"false"` | no |
| parameter\_group\_family | The name of the parameter group family to use with this instance | string | n/a | yes |
| skip\_final\_snapshot | Determines whether a final DB snapshot is created before the DB cluster is deleted | string | `"false"` | no |
| tag\_name\_identifier | Unique tag name identifier for all AWS resources that are grouped together | string | n/a | yes |
| vpc\_cidr\_block | CIDR block for the VPC | list | n/a | yes |
| vpc\_id |  | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| opa\_rds\_database\_name |  |
| opa\_rds\_endpoint | returns "host:port" |
| opa\_rds\_engine\_type |  |
| opa\_rds\_event\_subscriptions |  |
| opa\_rds\_host | returns "host" |
| opa\_rds\_identifier |  |
| opa\_rds\_kms\_key\_for\_db\_encryption |  |
| opa\_rds\_parameter\_group\_name |  |
| opa\_rds\_parametergroup\_event\_subscriptions |  |
| opa\_rds\_password\_key |  |
| opa\_rds\_port | returns "port" |
| opa\_rds\_security\_group\_id |  |
| opa\_rds\_username |  |

