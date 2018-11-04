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
  public_zone_id  = "Z2V9G6ECGZOW0G"
  private_name    = "enron.com"
  public_name     = "atlaskerr.com"
}

resource "aws_route53_zone" "internal" {
  name    = "${local.private_name}"
  comment = "Enron Internal DNS"
  vpc_id  = "${local.vpc_id}"
}

output "private_zone_id" {
  value = "${local.private_zone_id}"
}

output "public_zone_id" {
  value = "${local.public_zone_id}"
}

output "private_zone_domain_name" {
  value = "${local.private_name}"
}

output "public_zone_domain_name" {
  value = "${local.public_name}"
}
