terraform {
  backend "s3" {
    bucket         = "029620356096-tfstate-prodoptumopa"
    key            = "stage/terraform.state"
    dynamodb_table = "029620356096-tflock-prodoptumopa"
    encrypt        = "true"
    region         = "us-east-1"
  }

  required_version = "0.11.14"
}

data "terraform_remote_state" "shared" {
  backend = "s3"

  config = {
    bucket = "029620356096-tfstate-prodoptumopa"
    key    = "prod-shared/terraform.state"
    region = "us-east-1"
  }
}
