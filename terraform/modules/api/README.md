# OPA API

### Steps to Add a New API Method

Given a resource name like "new-resource" we can create a new API method as follows:

- Create subfolder api/new-resource and add the lambda python code + dependencies
- Copy opa-master.tf and rename to "new-resource.tf"
- Update "locals" in "new-resource.tf" with the desired values for the new method and lambda## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| api\_description | Internal API for OPA orchestration tasks | string | `"Internal API for OPA orchestration tasks"` | no |
| api\_name | Name of the API | string | `"opa-api"` | no |
| api\_policy | API policy JSON document | string | n/a | yes |
| artifacts\_s3\_id | S3 bucket for OPA artifacts | string | n/a | yes |
| data\_load\_service\_role\_name | The name of the Data Load Service role | string | n/a | yes |
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe | string | n/a | yes |
| environment\_vars | Environment variables which need to be passed to lambdas | map | `<map>` | no |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| hybrid\_cidr\_block | CIDR block for the hybrid network | list | n/a | yes |
| opa\_api\_source\_code\_s3\_bucket | S3 bucket with API lambda source code | string | n/a | yes |
| opa\_api\_source\_code\_s3\_key | S3 key with API lambda source code | string | n/a | yes |
| opa\_release\_sns\_role\_arn | OPA release step function SNS topic role arn | string | n/a | yes |
| private\_subnet\_ids | VPC private subnet ids | list | n/a | yes |
| project | Name of the Project | string | `"opa"` | no |
| redshift\_egress\_sg | the Redshift egress SG that will be attached to individual Lambdas that need it | string | n/a | yes |
| stage\_name | Stage for deployment of the API | string | `"dev"` | no |
| vpc\_cidr\_block | CIDR block for the VPC | list | n/a | yes |
| vpc\_id | VPC id | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| opa\_client\_env\_move\_lambda\_arn |  |
| opa\_client\_onboarding\_lambda\_arn |  |
| opa\_client\_redshift\_security\_lambda\_arn |  |
| opa\_deploy\_rw\_schema\_lambda\_arn |  |
| opa\_master\_lambda\_arn |  |
| opa\_mstr\_backup\_lambda\_arn |  |
| opa\_mstr\_migration\_lambda\_arn |  |
| opa\_mstr\_stack\_lambda\_arn |  |
| opa\_smoke\_test\_lambda\_arn |  |
| opa\_tf\_runner\_lambda\_arn |  |
| opa\_timezone\_change\_lambda\_arn |  |

