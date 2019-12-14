terraform {
  backend "s3" {
    bucket = "760182235631-tfstate-nonprodoptumopa"

    # use personal dev environment key
    key            = "dev-dusan/terraform.state"
    dynamodb_table = "760182235631-tflock-nonprodoptumopa"
    encrypt        = "true"
    region         = "us-east-1"
  }

  required_version = "0.11.14"
}

data "terraform_remote_state" "shared" {
  backend = "s3"

  config = {
    bucket = "760182235631-tfstate-nonprodoptumopa"
    key    = "nonprod-shared/terraform.state"
    region = "us-east-1"
  }
}
