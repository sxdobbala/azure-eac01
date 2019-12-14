data "aws_caller_identity" "current_identity" {}
data "aws_region" "current_region" {}

locals {
  aws_account_id = "${data.aws_caller_identity.current_identity.account_id}"
}
