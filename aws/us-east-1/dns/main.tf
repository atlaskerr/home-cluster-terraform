provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/dns/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  vpc_id          = "${data.terraform_remote_state.vpc.vpc_id}"
  private_zone_id = "${aws_route53_zone.internal.id}"
  dns_name        = "enron.com"
}

resource "aws_route53_zone" "internal" {
  name    = "${local.dns_name}"
  comment = "Enron Internal DNS"
  vpc_id  = "${local.vpc_id}"
}

output "private_zone_id" {
  value = "${local.private_zone_id}"
}

output "private_zone_domain_name" {
  value = "${local.dns_name}"
}
