# Creating a MSTR cloud instance

For now, I am using the same (null_resource) mechanisms to create.  Don is working on a go project.

Because of this, to tear down an instance requires a two step process

First, set state="stop" in the definition, then apply, it will run the "stopanddestroyenvironment.py" script

Then, remove the module block.

Not ideal, but that's how it works for now.
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| apikey | MSTR API Key | string | n/a | yes |
| app\_elb\_path | Application Load Balancer Path | string | n/a | yes |
| company |  | string | `"Optum"` | no |
| customer | Customer the MSTR instance is assigned to | string | n/a | yes |
| developerInstanceType | EC2 instance type for windows developer box e.g. r4.large | string | `""` | no |
| email |  | string | `"svopa_deploy@optum.com"` | no |
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe | string | n/a | yes |
| environmentName | MSTR Environment Name | string | n/a | yes |
| environmentType | MSTR Environment Type | string | n/a | yes |
| firstName |  | string | `"OPADeploy"` | no |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| lastName |  | string | `"ServiceAccount"` | no |
| microStrategyVersion | MSTR Version Number | string | `"10.11 Critical Update 1"` | no |
| mstrbak | MSTR Environment UID | string | `""` | no |
| opa\_release\_sns\_topic\_arn | OPA release SNS topic arn | string | `"null"` | no |
| platformInstanceType |  | string | `"r4.large"` | no |
| platformOS |  | string | `"Amazon Linux"` | no |
| rdsInstanceType |  | string | `"db.r4.large"` | no |
| rdsSize |  | string | `"5"` | no |
| state | MSTR Environment UID | string | `"start"` | no |

## Outputs

| Name | Description |
|------|-------------|
| environment\_id |  |

