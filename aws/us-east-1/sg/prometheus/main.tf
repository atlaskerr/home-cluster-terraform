provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/sg/prometheus/terraform.tfstate"
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
  vpc_id   = "${data.terraform_remote_state.vpc.vpc_id}"
  vpc_name = "${data.terraform_remote_state.vpc.name}"
  vpc_cidr = "${data.terraform_remote_state.vpc.cidr}"
  sg_id    = "${aws_security_group.prometheus.id}"

  admin_vpn_c = "${data.terraform_remote_state.cidrs.admin_vpn_c}"
  admin_vpn_e = "${data.terraform_remote_state.cidrs.admin_vpn_e}"
  grafana_c   = "${data.terraform_remote_state.cidrs.grafana_c}"
}

resource "aws_security_group" "prometheus" {
  name        = "prometheus"
  description = "Prometheus Security Group"
  vpc_id      = "${local.vpc_id}"

  tags {
    Name = "prometheus-sg-${local.vpc_name}"
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

resource "aws_security_group_rule" "prometheus_in_admin_vpn" {
  description = "Allow inbound prometheus traffic from Admin VPN subnets"
  type        = "ingress"
  from_port   = "9090"
  to_port     = "9090"
  protocol    = "tcp"

  cidr_blocks = [
    "${local.admin_vpn_c}",
    "${local.admin_vpn_e}",
  ]

  security_group_id = "${local.sg_id}"
}

resource "aws_security_group_rule" "prometheus_in_grafana" {
  description = "Allow inbound prometheus traffic from grafana"
  type        = "ingress"
  from_port   = "9090"
  to_port     = "9090"
  protocol    = "tcp"

  cidr_blocks = ["${local.grafana_c}"]

  security_group_id = "${local.sg_id}"
}

resource "aws_security_group_rule" "all_ports_out" {
  description       = "Allow all outbound traffic"
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
