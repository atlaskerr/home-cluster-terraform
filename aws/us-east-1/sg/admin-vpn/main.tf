provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/sg/admin-vpn/terraform.tfstate"
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
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"
  sg_id  = "${aws_security_group.admin_vpn.id}"
}

resource "aws_security_group" "admin_vpn" {
  name        = "admin-vpn"
  description = "Admin VPN Security Group"
  vpc_id      = "${local.vpc_id}"

  tags {
    Name = "Admin VPN"
  }
}

resource "aws_security_group_rule" "all_traffic_in" {
  type              = "ingress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${local.sg_id}"
}

resource "aws_security_group_rule" "all_traffic_out" {
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${local.sg_id}"
}

output "sg_id" {
  value = "${local.sg_id}"
}
