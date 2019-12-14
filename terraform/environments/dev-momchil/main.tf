locals {
  global_tags = {
    "${var.tag_prefix}:environment" = "${var.env_prefix}"
    "${var.tag_prefix}:application" = "${var.application_tag}"
    "terraform"                     = "true"
  }

  ci_email             = "momchil.georgiev@optum.com"
  opa_operations_email = "momchil.georgiev@optum.com"
}
