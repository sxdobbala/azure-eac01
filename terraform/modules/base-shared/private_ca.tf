# Create private key for CA cert
resource "tls_private_key" "ca_private_key" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

# Save private key to SSM
resource "aws_ssm_parameter" "ca_private_key" {
  name      = "/${var.env_prefix}/ca_private_key"
  type      = "SecureString"
  value     = "${tls_private_key.ca_private_key.private_key_pem}"
  overwrite = "true"
  tags      = "${var.global_tags}"
}

# Create private CA cert
resource "tls_self_signed_cert" "ca_cert" {
  key_algorithm     = "RSA"
  private_key_pem   = "${aws_ssm_parameter.ca_private_key.value}"
  is_ca_certificate = true

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
  ]

  subject {
    common_name  = "${var.env_prefix}.cloud.opa"
    organization = "OPA cloud"
  }
}

# Save CA public cert to SSM
resource "aws_ssm_parameter" "ca_public_cert" {
  name      = "/${var.env_prefix}/ca_public_cert"
  type      = "String"
  value     = "${tls_self_signed_cert.ca_cert.cert_pem}"
  overwrite = "true"
  tags      = "${var.global_tags}"
}

# Save CA public cert to artifacts bucket so it can be downloaded readily to be trusted
resource "aws_s3_bucket_object" "ca_public_cert" {
  bucket  = "${module.s3-opa-artifacts.id}"
  key     = "${var.env_prefix}/ca_public_cert"
  content = "${tls_self_signed_cert.ca_cert.cert_pem}"
  tags    = "${var.global_tags}"
}

resource "aws_ssm_parameter" "ca_public_cert_s3_path" {
  name      = "ca_public_cert_s3_path"
  type      = "String"
  value     = "/${var.env_prefix}/ca_public_cert"
  overwrite = "true"
  tags      = "${var.global_tags}"
}
