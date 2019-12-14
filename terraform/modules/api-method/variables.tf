# API Gateway variables

variable "api_name" {
  description = "The name of the REST API"
  default     = "opa"
}

variable "api_gateway_id" {
  description = "The id of the API Gateway to deploy to"
}

variable "api_gateway_root_resource_id" {
  description = "The root resource id of the API Gateway to deploy to"
}

variable "api_stage_name" {
  description = "The stage name for the API deployment (qa/dev/prov/stage/v1/etc...)"
  default     = "dev"
}

variable "api_resource" {
  description = "The API Gateway resource"
}

variable "api_method" {
  description = "The HTTP method"
  default     = "GET"
}

# Lambda variables

variable "lambda_function_name" {
  description = "The name of the lambda function"
}

variable "lambda_description" {
  description = "A brief description of the lambda function"
}

variable "lambda_runtime" {
  description = "The runtime used to execute the lambda function"
  default     = "python3.6"
}

variable "lambda_handler" {
  description = "The main entry point of the lambda function"
}

variable "lambda_memory_size" {
  description = "Memory in MB to allocate for lambda usage"
  default     = "128"
}

variable "lambda_timeout" {
  description = "Timeout in seconds"
  default     = "300"
}

variable "lambda_subnet_ids" {
  description = "The subnets which the lambda is allowed to access"
  type        = "list"
}

variable "lambda_security_group_ids" {
  description = "The security groups which the lambda should use for access to the VPC/subnets"
  type        = "list"
}

# Environment vars can't be null, so set a default; this will get overwritten if passed in
variable "lambda_environment_vars" {
  description = "Environment variables which need to be passed to the lambda"
  type        = "map"

  default = {
    default = "default"
  }
}

variable "lambda_custom_inline_policy_count" {
  description = "Number of custom policies to apply to the lambda exec role"
  default     = 0
}

variable "lambda_custom_inline_policies" {
  description = "List of custom policies to apply to the lambda exec role, provides lambda access to AWS resources"

  default = [{
    custom_inline_name   = "null"
    custom_inline_policy = "{\"Version\": \"2012-10-17\",\"Statement\":[]}"
  }]
}

variable "lambda_custom_managed_policies" {
  description = "ARN of additional AWS managed policies to attach to the IAM Role. Module automatically includes service-role/AWSLambdaBasicExecutionRole"
  default     = []
}

variable "lambda_s3_bucket" {
  description = "S3 bucket with the lambda code archive"
}

variable "lambda_s3_key" {
  description = "S3 key with the lambda code archive"
}

variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}
