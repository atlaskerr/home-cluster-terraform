locals {
  vpc_cidr               = "192.168.0.0/16"
  region                 = "us-east-1"
  vpc_name               = "enron"
  vpc_id                 = "${aws_vpc.enron.id}"
  public_route_table_id  = "${aws_route_table.public.id}"
  private_route_table_id = "${aws_route_table.private.id}"
}

provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_vpc" "enron" {
  cidr_block           = "${local.vpc_cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "vpc-${local.vpc_name}-${local.region}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = "${local.vpc_id}"

  tags {
    Name = "public-rt-${local.vpc_name}-${local.region}"
  }
}

# Route table for private subnets
resource "aws_route_table" "private" {
  vpc_id = "${local.vpc_id}"

  tags {
    Name = "private-rt-${local.vpc_name}-${local.region}"
  }
}

output "vpc_id" {
  value = "${local.vpc_id}"
}

output "region" {
  value = "${local.region}"
}

output "name" {
  value = "${local.vpc_name}"
}

output "cidr" {
  value = "${local.vpc_cidr}"
}

output "rt_public_id" {
  value = "${local.public_route_table_id}"
}

output "rt_private_id" {
  value = "${local.private_route_table_id}"
}
