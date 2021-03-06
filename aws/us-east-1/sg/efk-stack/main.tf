provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/sg/efk-stack/terraform.tfstate"
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
  vpc_id              = "${data.terraform_remote_state.vpc.vpc_id}"
  vpc_name            = "${data.terraform_remote_state.vpc.name}"
  admin_vpn_c         = "${data.terraform_remote_state.cidrs.admin_vpn_c}"
  admin_vpn_e         = "${data.terraform_remote_state.cidrs.admin_vpn_e}"
  elasticsearch_sg_id = "${aws_security_group.efk_elasticsearch.id}"
}

resource "aws_security_group" "efk_elasticsearch" {
  name        = "efk-elasticsearch"
  description = "Elasticsearch for EFK Stack Security Group"
  vpc_id      = "${local.vpc_id}"

  tags {
    Name = "efk-elasticsearch-sg-${local.vpc_name}"
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

  security_group_id = "${local.elasticsearch_sg_id}"
}

resource "aws_security_group_rule" "http_out_all" {
  description       = "Allow outbound HTTP to everywhere"
  type              = "egress"
  from_port         = "80"
  to_port           = "80"
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${local.elasticsearch_sg_id}"
}

resource "aws_security_group_rule" "https_out_all" {
  description       = "Allow outbound HTTPS to everywhere"
  type              = "egress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${local.elasticsearch_sg_id}"
}

resource "aws_security_group_rule" "https_in_all" {
  description       = "Allow inbound HTTPS from everywhere"
  type              = "ingress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${local.elasticsearch_sg_id}"
}

output "elasticsearch_sg_id" {
  value = "${local.elasticsearch_sg_id}"
}
