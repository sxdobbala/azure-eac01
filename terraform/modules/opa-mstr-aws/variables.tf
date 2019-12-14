variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}

variable "s3_artifacts_id" {
  description = "S3 bucket where the archives are uploaded"
}
