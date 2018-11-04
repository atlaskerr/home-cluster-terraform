provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/s3/terraform.tfstate"
    region = "us-east-1"
  }
}
