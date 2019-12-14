# Instance of redshift, plus an security group for egress to be assigned to server that need to access.  Also, ssm parameters to locate database, username, password## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| appstream\_sg\_id | appstream security group ID for ingress | string | n/a | yes |
| aws\_az |  | string | n/a | yes |
| cluster\_type |  | string | n/a | yes |
| database\_name | The name of the first database to be created when the cluster is created. | string | n/a | yes |
| enhanced\_vpc\_routing | The port on which the DB accepts connections | string | `"true"` | no |
| final\_snapshot\_identifier |  | string | `""` | no |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| hybrid\_subnet\_cidr\_blocks |  | list | `<list>` | no |
| instance\_type |  | string | n/a | yes |
| is\_hybrid |  | string | `"false"` | no |
| label | Unique Environment Label (sets cluster name as well as labels for other resources) | string | n/a | yes |
| master\_username |  | string | n/a | yes |
| number\_of\_nodes |  | string | n/a | yes |
| redshift\_egress\_sg\_id | redshift egress security group ID for ingress | string | n/a | yes |
| redshift\_iam\_roles\_arn | IAM roles list for Redshift | list | `<list>` | no |
| snapshot\_identifier | TODO: make this optional in redshift-with-security module; underlying EAC defaults to empty | string | n/a | yes |
| subnet\_cidr\_blocks |  | list | n/a | yes |
| subnet\_ids |  | list | n/a | yes |
| vpc\_id |  | string | n/a | yes |
| vpc\_s3\_endpoint\_cidr\_blocks | CIDR Blocks of the VPC Endpoint for S3 | list | n/a | yes |
| wlm\_json\_configuration | WLM json configuration. See https://docs.aws.amazon.com/redshift/latest/mgmt/workload-mgmt-config.html | string | `"[{\"queue_type\":\"auto\",\"auto_wlm\": true, \"priority\": \"normal\", \"query_group\":[\"MSTR*\"],\"query_group_wild_card\":1,\"user_group\":[],\"user_group_wild_card\":0, \"concurrency_scaling\":\"auto\"},{\"queue_type\":\"auto\",\"auto_wlm\": true, \"priority\": \"high\", \"query_group\":[],\"query_group_wild_card\":0,\"user_group\":[],\"user_group_wild_card\":0},{\"short_query_queue\":true}]"` | no |

## Outputs

| Name | Description |
|------|-------------|
| redshift\_egress\_security\_group\_id |  |
| redshift\_ingress\_security\_group\_id |  |
| redshift\_port |  |

