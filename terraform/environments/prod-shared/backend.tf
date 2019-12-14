terraform {
  backend "s3" {
    bucket         = "029620356096-tfstate-prodoptumopa"
    key            = "prod-shared/terraform.state"
    dynamodb_table = "029620356096-tflock-prodoptumopa"
    encrypt        = "true"
    region         = "us-east-1"
  }
}
