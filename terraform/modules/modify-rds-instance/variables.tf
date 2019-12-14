variable "is_prod" {
  description = "Flag used to determine whether to create prod or non-prod resources"
  default     = "true"
}

variable "tag_filters" {
  # For example, "{'aws:cloudformation:logical-id':'RDSMySQL', 'Environment':'qa'}"
  description = "A String giving tag name and value for all the filters. Follow the pattern {'Key1':'Value1','Key2':'Value2'}"
}

variable "rds_instance_class" {
  description = "The target instance class that need to be modified to."
}
