variable "resource_type" {
  description = "The type of resource. rds or redshift."
}

variable "tag_filters" {
  # For example, "{'aws:cloudformation:logical-id':'RDSMySQL', 'Environment':'qa'}"
  description = "A String giving tag name and value for all the filters. Follow the pattern {'Key1':'Value1','Key2':'Value2'}"
}
