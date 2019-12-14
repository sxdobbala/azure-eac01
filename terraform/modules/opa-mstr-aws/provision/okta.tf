# We're creating dummy Okta secrets - they can be updated to the real values later in a manual or automated step.
# However, for backward compatibility with existing clients, assume that the default value of create_dummy_okta_secrets is 'false'.
# New clients going forward should pass 'true' for the create_dummy_okta_secrets flag.

locals {
  okta_count = "${var.create_dummy_okta_secrets == "true" ? 1 : 0}"
}

resource "aws_ssm_parameter" "sso_okta_secret" {
  count     = "${local.okta_count}"
  name      = "/${var.env_id}/sso_okta_secret"
  type      = "SecureString"
  value     = "dummy"
  overwrite = false
}

resource "aws_ssm_parameter" "sso_esm_admin_password" {
  count     = "${local.okta_count}"
  name      = "/${var.env_id}/sso_esm_admin_password"
  type      = "SecureString"
  value     = "dummy"
  overwrite = false
}
