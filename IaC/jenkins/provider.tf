terraform {
  backend "s3" {
    bucket = "terraform-tfstate-bucket-232133"
    region = "us-east-1"
    key    = "terraform/jenkins"
  }
}

provider "aws" {
  region = "us-east-1"
}

data "terraform_remote_state" "state" {
  backend = "s3"
  config = {
    bucket = "terraform-tfstate-bucket-232133"
    region = "us-east-1"
    key    = "terraform/prereqs"
  }
}
