locals {
  account_id = "${data.aws_caller_identity.current_identity.account_id}"
  aws_region = "${data.aws_region.current_region.name}"
}

data "aws_caller_identity" "current_identity" {}
data "aws_region" "current_region" {}
