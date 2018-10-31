provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/igw/terraform.tfstate"
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

data "terraform_remote_state" "cidrs" {
  backend = "s3"

  config {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/cidrs/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  vpc_id        = "${data.terraform_remote_state.vpc.vpc_id}"
  rt_public_id  = "${data.terraform_remote_state.vpc.rt_public_id}"
  rt_private_id = "${data.terraform_remote_state.vpc.rt_private_id}"
  cidr_block    = "${data.terraform_remote_state.cidrs.igw}"
  gateway_id    = "${aws_internet_gateway.igw.id}"
  subnet_id     = "${aws_subnet.igw.id}"
  nat_id        = "${aws_nat_gateway.nat.id}"
  nat_eip_id    = "${aws_eip.nat.id}"
}

# Internet gateway for instances with public IPs
resource "aws_internet_gateway" "igw" {
  vpc_id = "${local.vpc_id}"
}

resource "aws_route" "igw" {
  route_table_id         = "${local.rt_public_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${local.gateway_id}"
}

resource "aws_subnet" "igw" {
  availability_zone = "us-east-1c"
  cidr_block        = "${local.cidr_block}"
  vpc_id            = "${local.vpc_id}"
}

resource "aws_route_table_association" "igw" {
  subnet_id      = "${local.subnet_id}"
  route_table_id = "${local.rt_public_id}"
}

# NAT Gateway for private subnets that need internet access
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${local.nat_eip_id}"
  subnet_id     = "${local.subnet_id}"
}

resource "aws_route" "nat" {
  route_table_id         = "${local.rt_private_id}"
  nat_gateway_id         = "${local.nat_id}"
  destination_cidr_block = "0.0.0.0/0"
}

output "igw_id" {
  value = "${local.gateway_id}"
}

output "nat_id" {
  value = "${local.nat_id}"
}
