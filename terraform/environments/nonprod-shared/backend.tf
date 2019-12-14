terraform {
  backend "s3" {
    bucket         = "760182235631-tfstate-nonprodoptumopa"
    key            = "nonprod-shared/terraform.state"
    dynamodb_table = "760182235631-tflock-nonprodoptumopa"
    encrypt        = "true"
    region         = "us-east-1"
  }
}
