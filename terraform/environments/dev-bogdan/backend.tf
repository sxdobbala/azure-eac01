terraform {
  backend "s3" {
    bucket         = "760182235631-tfstate-nonprodoptumopa"
    key            = "dev-bogdan/terraform.state"
    dynamodb_table = "760182235631-tflock-nonprodoptumopa"
    encrypt        = "true"
    region         = "us-east-1"
  }

  #Not adding required_version.  The idea is that if this is only applied/planned via jenkins, it should be the same
}

data "terraform_remote_state" "shared" {
  backend = "s3"

  config = {
    bucket = "760182235631-tfstate-nonprodoptumopa"
    key    = "nonprod-shared/terraform.state"
    region = "us-east-1"
  }
}
