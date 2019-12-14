variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

variable "environmentType" {
  type        = "string"
  description = "MSTR Environment Type"
}

variable "environmentName" {
  type        = "string"
  description = "MSTR Environment Name"
}

variable "microStrategyVersion" {
  type        = "string"
  description = "MSTR Version Number"
  default     = "10.11 Critical Update 1"
}

variable "mstrbak" {
  type        = "string"
  description = "MSTR Environment UID"
  default     = ""
}

variable "state" {
  type        = "string"
  description = "MSTR Environment UID"
  default     = "start"
}

variable "apikey" {
  type        = "string"
  description = "MSTR API Key"
}

variable "firstName" {
  type    = "string"
  default = "OPADeploy"
}

variable "lastName" {
  type    = "string"
  default = "ServiceAccount"
}

variable "email" {
  type    = "string"
  default = "svopa_deploy@optum.com"
}

variable "company" {
  type    = "string"
  default = "Optum"
}

variable "developerInstanceType" {
  type        = "string"
  default     = ""                                                          # Set to empty string to make sure we don't create developer box by default since it's not hardened and is not needed.
  description = "EC2 instance type for windows developer box e.g. r4.large"
}

variable "platformInstanceType" {
  type    = "string"
  default = "r4.large"
}

variable "platformOS" {
  type    = "string"
  default = "Amazon Linux"
}

variable "rdsInstanceType" {
  type    = "string"
  default = "db.r4.large"
}

variable "rdsSize" {
  type    = "string"
  default = "5"
}

variable "app_elb_path" {
  type        = "string"
  description = "Application Load Balancer Path"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}

variable "opa_release_sns_topic_arn" {
  description = "OPA release SNS topic arn"
  default     = "null"
}

variable "customer" {
  type        = "string"
  description = "Customer the MSTR instance is assigned to"
}
