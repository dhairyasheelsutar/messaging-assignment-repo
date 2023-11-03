terraform {
    backend "s3" {
        bucket = "terraform-tfstate-bucket-232133"
        region = "us-east-1"
        key = "terraform"
    }
}

provider "aws" {
    region = "us-east-1"
}

