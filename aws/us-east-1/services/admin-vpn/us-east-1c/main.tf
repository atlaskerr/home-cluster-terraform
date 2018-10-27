provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/services/admin-vpn/us-east-1c/terraform.tfstate"
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

data "terraform_remote_state" "ssh_keys" {
  backend = "s3"

  config {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/ssh-keys/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "dns" {
  backend = "s3"

  config {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/dns/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "sg_admin_vpn" {
  backend = "s3"

  config {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/sg/admin-vpn/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ami" "centos" {
  owners      = ["679593333241"]
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

locals {
  az        = "us-east-1c"
  cidr      = "${data.terraform_remote_state.cidrs.admin_vpn_c}"
  rt_id     = "${data.terraform_remote_state.vpc.rt_public_id}"
  key_name  = "${data.terraform_remote_state.ssh_keys.atlas}"
  zone_id   = "${data.terraform_remote_state.dns.private_zone_id}"
  vpc_id    = "${data.terraform_remote_state.vpc.vpc_id}"
  sg        = "${data.terraform_remote_state.sg_admin_vpn.sg_id}"
  ami       = "${data.aws_ami.centos.id}"
  subnet_id = "${aws_subnet.admin_vpn.id}"
  ip        = "${aws_instance.admin_vpn.private_ip}"
}

resource "aws_subnet" "admin_vpn" {
  vpc_id                  = "${local.vpc_id}"
  availability_zone       = "${local.az}"
  cidr_block              = "${local.cidr}"
  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "admin_vpn" {
  subnet_id      = "${local.subnet_id}"
  route_table_id = "${local.rt_id}"
}

resource "aws_instance" "admin_vpn" {
  ami                    = "${local.ami}"
  key_name               = "${local.key_name}"
  instance_type          = "t3.micro"
  subnet_id              = "${local.subnet_id}"
  vpc_security_group_ids = ["${local.sg}"]

  tags {
    Name = "Admin VPN"
  }
}

resource "aws_route53_record" "admin_vpn" {
  zone_id = "${local.zone_id}"
  name    = "admin-vpn.us-east-1c.enron.io"
  type    = "A"
  ttl     = "300"
  records = ["${local.ip}"]
}
