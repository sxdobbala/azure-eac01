## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe | string | n/a | yes |
| maintenance\_window\_schedule\_cutoff | The number of hours before the end of the maintenance window that Systems Manager stops scheduling new tasks for execution | string | n/a | yes |
| maintenance\_window\_schedule\_duration | Maintenance window running hours | string | n/a | yes |
| maintenance\_window\_schedule\_time | Follow cron rules. Eg, cron(30 16 * * ? *) : every day at 16:30 | string | n/a | yes |
| maintenance\_window\_schedule\_timezone | INeed to use ANA timezone, https://en.wikipedia.org/wiki/List_of_tz_database_time_zones | string | `"America/New_York"` | no |
| task\_arn | The ARN of task. Eg, AWS-UpdateSSMAgent or AWS-RunShellScript | string | n/a | yes |
| task\_description | The description of maintenance window task | string | n/a | yes |
| task\_name | The name of maintenance window task | string | n/a | yes |

