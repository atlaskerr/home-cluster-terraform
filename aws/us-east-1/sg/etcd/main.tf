provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/sg/etcd/terraform.tfstate"
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
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

  admin_vpn_c = "${data.terraform_remote_state.cidrs.admin_vpn_c}"
  admin_vpn_e = "${data.terraform_remote_state.cidrs.admin_vpn_e}"
  etcd_lb     = "${data.terraform_remote_state.cidrs.etcd_lb}"
  etcd_b      = "${data.terraform_remote_state.cidrs.etcd_b}"
  etcd_c      = "${data.terraform_remote_state.cidrs.etcd_c}"
  etcd_d      = "${data.terraform_remote_state.cidrs.etcd_d}"
  etcd_e      = "${data.terraform_remote_state.cidrs.etcd_e}"
  etcd_f      = "${data.terraform_remote_state.cidrs.etcd_f}"

  sg_id  = "${aws_security_group.etcd.id}"
}

resource "aws_security_group" "etcd" {
  name        = "etcd"
  description = "Etcd Security Group"
  vpc_id      = "${local.vpc_id}"

  tags {
    Name = "Etcd"
  }
}

resource "aws_security_group_rule" "ssh_in_admin_vpn" {
  description = "Allow inbound SSH from Admin VPN subnets"
  type        = "ingress"
  from_port   = "22"
  to_port     = "22"
  protocol    = "tcp"

  cidr_blocks = [
    "${local.admin_vpn_c}",
    "${local.admin_vpn_e}",
  ]

  security_group_id = "${local.sg_id}"
}

resource "aws_security_group_rule" "etcd_in_lb" {
  description       = "Allow inbound Etcd client traffic from load balancer subnet"
  type              = "ingress"
  from_port         = "2379"
  to_port           = "2379"
  protocol          = "tcp"
  cidr_blocks       = ["${local.etcd_lb}"]
  security_group_id = "${local.sg_id}"
}

resource "aws_security_group_rule" "etcd_in_peer" {
  description = "Allow inbound Etcd peer traffic from Etcd subnets"
  type        = "ingress"
  from_port   = "2380"
  to_port     = "2380"
  protocol    = "tcp"

  cidr_blocks = [
    "${local.etcd_b}",
    "${local.etcd_c}",
    "${local.etcd_d}",
    "${local.etcd_e}",
    "${local.etcd_f}",
  ]

  security_group_id = "${local.sg_id}"
}

resource "aws_security_group_rule" "etcd_in_client" {
  description = "Allow inbound Etcd client traffic from Etcd subnets"
  type        = "ingress"
  from_port   = "2379"
  to_port     = "2379"
  protocol    = "tcp"

  cidr_blocks = [
    "${local.etcd_b}",
    "${local.etcd_c}",
    "${local.etcd_d}",
    "${local.etcd_e}",
    "${local.etcd_f}",
  ]

  security_group_id = "${local.sg_id}"
}

resource "aws_security_group_rule" "etcd_in_admin_vpn" {
  description = "Allow inbound Etcd client traffic from Admin VPN subnets"
  type        = "ingress"
  from_port   = "2379"
  to_port     = "2379"
  protocol    = "tcp"

  cidr_blocks = [
    "${local.admin_vpn_c}",
    "${local.admin_vpn_e}"
  ]

  security_group_id = "${local.sg_id}"
}

resource "aws_security_group_rule" "etcd_out_peer" {
  description = "Allow outbound Etcd peer traffic to Etcd subnets"
  type        = "egress"
  from_port   = "2380"
  to_port     = "2380"
  protocol    = "tcp"

  cidr_blocks = [
    "${local.etcd_b}",
    "${local.etcd_c}",
    "${local.etcd_d}",
    "${local.etcd_e}",
    "${local.etcd_f}",
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
