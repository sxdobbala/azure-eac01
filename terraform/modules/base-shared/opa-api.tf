module "opa-api" {
  source          = "../../modules/opa-api/"
  env_prefix      = "${var.env_prefix}"
  s3_artifacts_id = "${module.s3-opa-artifacts.id}"
}
