variable "s3_bucket_name" {
  description = "The name of bucket to store session logs. Specifying this enables writing session output to an Amazon S3 bucket."
}

variable "s3_key_prefix" {
  description = "To write output to a sub-folder, enter a sub-folder name."
}

variable "cloudwatch_log_group_name" {
  description = "The name of the log group to upload session logs to. Specifying this enables sending session output to CloudWatch Logs."
}

variable "global_tags" {
  description = "Additional global tags to be applied to created resources"
  type        = "map"
}
