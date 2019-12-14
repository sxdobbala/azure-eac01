# API Gateway Method & Associated Lambda

### Features
- Uploads lambda zip bundle to AWS during `terraform apply`
- Deploys lambda function into pre-defined VPC/subnets
- Creates API gateway method and integration with lambda
- Supports configuration of additional managed/inline policies
- At the moment supports trigger mechanism of lambda via API Gateway only

## Example Usage
```hcl
locals {
  api_resource = "opa-master"  
  lambda_function_name = "${var.project}-${var.stage_name}-${local.api_resource}"
  lambda_description = "OPA Master Lambda for loading/saving client configurations"
  lambda_source_code = "${path.module}/opa-master/"
  lambda_handler = "opa-master.lambda_handler"
}

# Module creating the api method and lambda for load/save access to OPA Master database
module "api_method_opa_master" {
  source         = "../api-method/"

  # name of the api - defaults to 'opa' 
  api_name       = "${var.api_name}"
  # name of the resource on the API Gateway - should to be short and descriptive
  api_resource   = "${local.api_resource}"
  # REST method(s) supported by this api method - can be ANY, GET, PUT, POST, etc.
  api_method     = "ANY"
  # region where the method is deployed
  api_region     = "${var.region}"
  # api stage name
  api_stage_name = "${var.stage_name}"

  # provide details about the lambda function
  lambda_description   = "${local.lambda_description}"
  # the lambda function name should fit the pattern [project-stage-resource]
  lambda_function_name = "${local.lambda_function_name}"
  # should point to a subfolder containing all lambda source code
  lambda_source_code   = "${local.lambda_source_code}"
  # main entry point for the lambda function - needs to fit the pattern [python_script.handler_method]
  # otherwise lambda will throw an error that it's unable to find the main entry point
  lambda_handler       = "${local.lambda_handler}"

  # these should be set to a pre-configured VPC with private subnets
  lambda_subnet_ids         = ["${var.subnet_ids}"]
  lambda_security_group_ids = ["${var.security_group_ids}"]

  # custom managed policies can be supplied
  lambda_custom_managed_policies = [
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
  ]

  # custom inline policies can also be specified
  #lambda_custom_inline_policy_count = 1
  #lambda_custom_inline_policies = [{
  #  custom_inline_name   = "null"
  #  custom_inline_policy = "{\"Version\": \"2012-10-17\",\"Statement\":[]}"
  #}]    
}
```



## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| api\_gateway\_id | The id of the API Gateway to deploy to | string | n/a | yes |
| api\_gateway\_root\_resource\_id | The root resource id of the API Gateway to deploy to | string | n/a | yes |
| api\_method | The HTTP method | string | `"GET"` | no |
| api\_name | The name of the REST API | string | `"opa"` | no |
| api\_resource | The API Gateway resource | string | n/a | yes |
| api\_stage\_name | The stage name for the API deployment (qa/dev/prov/stage/v1/etc...) | string | `"dev"` | no |
| env\_prefix | Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe | string | n/a | yes |
| global\_tags | Additional global tags to be applied to created resources | map | n/a | yes |
| lambda\_custom\_inline\_policies | List of custom policies to apply to the lambda exec role, provides lambda access to AWS resources | list | `<list>` | no |
| lambda\_custom\_inline\_policy\_count | Number of custom policies to apply to the lambda exec role | string | `"0"` | no |
| lambda\_custom\_managed\_policies | ARN of additional AWS managed policies to attach to the IAM Role. Module automatically includes service-role/AWSLambdaBasicExecutionRole | list | `<list>` | no |
| lambda\_description | A brief description of the lambda function | string | n/a | yes |
| lambda\_environment\_vars | Environment variables which need to be passed to the lambda | map | `<map>` | no |
| lambda\_function\_name | The name of the lambda function | string | n/a | yes |
| lambda\_handler | The main entry point of the lambda function | string | n/a | yes |
| lambda\_memory\_size | Memory in MB to allocate for lambda usage | string | `"128"` | no |
| lambda\_runtime | The runtime used to execute the lambda function | string | `"python3.6"` | no |
| lambda\_s3\_bucket | S3 bucket with the lambda code archive | string | n/a | yes |
| lambda\_s3\_key | S3 key with the lambda code archive | string | n/a | yes |
| lambda\_security\_group\_ids | The security groups which the lambda should use for access to the VPC/subnets | list | n/a | yes |
| lambda\_subnet\_ids | The subnets which the lambda is allowed to access | list | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| api\_url |  |
| arn |  |
| function\_name |  |
| http\_method |  |
| invoke\_arn |  |
| qualified\_arn |  |
| role\_arn |  |
| role\_name |  |
| source\_code\_hash |  |
| version |  |

