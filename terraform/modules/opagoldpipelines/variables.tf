variable "name" {
  description = "Name for the Pipeline"
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}
