terraform {
  backend "s3" {
    bucket         = "760182235631-tfstate-opa-ci"
    key            = "opa-ci/terraform.tfstate"
    dynamodb_table = "760182235631-tflock-opa-ci"
    encrypt        = "true"
    region         = "us-west-2"
  }
}

# data "terraform_remote_state" "shared" {
#   backend = "s3"
#   config = {
#     bucket = "760182235631-tfstate-nonprodoptumopa"
#     key    = "nonprod-shared/terraform.state"
#     region = "us-east-1"
#   }
# }

