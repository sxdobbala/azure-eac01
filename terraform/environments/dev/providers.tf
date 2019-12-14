provider "aws" {
  region  = "${var.aws_region}"
  version = "~> 2.34.0"
  alias   = "default"
}

provider "aws" {
  region  = "${var.aws_replication_region}"
  version = "~> 2.34.0"
  alias   = "replication"
}

provider "template" {
  version = "~> 2.1.2"
  alias   = "default"
}

provider "null" {
  version = "~> 2.1.2"
  alias   = "default"
}

provider "archive" {
  version = "~> 1.1"
  alias   = "default"
}

provider "random" {
  version = "~> 2.2.1"
  alias   = "default"
}

provider "external" {
  version = "~> 1.1"
  alias   = "default"
}

provider "tls" {
  version = "~> 2.0.1"
  alias   = "default"
}

provider "local" {
  version = "~> 1.4"
  alias   = "default"
}
