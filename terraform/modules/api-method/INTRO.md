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



