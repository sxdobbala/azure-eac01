terraform {
  backend "s3" {
    bucket         = "760182235631-tfstate-nonprodoptumopa"
    key            = "dev-nihanshu/terraform.state"
    dynamodb_table = "760182235631-tflock-nonprodoptumopa"
    encrypt        = "true"
    region         = "us-east-1"
  }
}
data "terraform_remote_state" "shared" {
  backend = "s3"

  config = {
    bucket = "760182235631-tfstate-nonprodoptumopa"
    key    = "nonprod-shared/terraform.state"
    region = "us-east-1"
  }
}
