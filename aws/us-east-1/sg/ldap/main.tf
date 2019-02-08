provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/sg/ldap/terraform.tfstate"
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
  vpc_id       = "${data.terraform_remote_state.vpc.vpc_id}"
  admin_vpn_c  = "${data.terraform_remote_state.cidrs.admin_vpn_c}"
  admin_vpn_e  = "${data.terraform_remote_state.cidrs.admin_vpn_e}"
  prometheus_c = "${data.terraform_remote_state.cidrs.prometheus_c}"
  sg_id        = "${aws_security_group.ldap.id}"
}

resource "aws_security_group" "ldap" {
  name        = "ldap"
  description = "LDAP Security Group"
  vpc_id      = "${local.vpc_id}"

  tags {
    Name = "LDAP"
  }
}

resource "aws_security_group_rule" "ssh_in_admin_vpn" {
  description       = "Allow inbound SSH from Admin VPN subnets"
  type              = "ingress"
  from_port         = "22"
  to_port           = "22"
  protocol          = "tcp"
  cidr_blocks       = ["${local.admin_vpn_c}", "${local.admin_vpn_e}"]
  security_group_id = "${local.sg_id}"
}

resource "aws_security_group_rule" "ldaps_in_all" {
  description       = "Allow inbound LDAPS from everywhere"
  type              = "ingress"
  from_port         = "636"
  to_port           = "636"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${local.sg_id}"
}

resource "aws_security_group_rule" "node_exporter_out" {
  description = "Allow inbound node_exporter traffic from prometheus subnets"
  type        = "ingress"
  from_port   = "9100"
  to_port     = "9100"
  protocol    = "TCP"

  cidr_blocks = [
    "${local.prometheus_c}",
  ]

  security_group_id = "${local.sg_id}"
}

resource "aws_security_group_rule" "http_out_all" {
  description       = "Allow outbound HTTP to everywhere"
  type              = "egress"
  from_port         = "80"
  to_port           = "80"
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${local.sg_id}"
}

resource "aws_security_group_rule" "https_out_all" {
  description       = "Allow outbound HTTPS to everywhere"
  type              = "egress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${local.sg_id}"
}

output "sg_id" {
  value = "${local.sg_id}"
}
