provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/services/ldap/us-east-1c/terraform.tfstate"
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

data "terraform_remote_state" "dns" {
  backend = "s3"

  config {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/dns/terraform.tfstate"
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

data "terraform_remote_state" "sg_ldap" {
  backend = "s3"

  config {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/sg/ldap/terraform.tfstate"
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
  az             = "us-east-1c"
  vpc_id         = "${data.terraform_remote_state.vpc.vpc_id}"
  vpc_name       = "${data.terraform_remote_state.vpc.name}"
  rt_id          = "${data.terraform_remote_state.vpc.rt_public_id}"
  key_name       = "${data.terraform_remote_state.ssh_keys.atlas}"
  cidr           = "${data.terraform_remote_state.cidrs.ldap_c}"
  sg_id          = "${data.terraform_remote_state.sg_ldap.sg_id}"
  zone_id        = "${data.terraform_remote_state.dns.private_zone_id}"
  ami            = "${data.aws_ami.centos.id}"
  subnet_id      = "${aws_subnet.ldap.id}"
  private_ip     = "${aws_instance.ldap.private_ip}"
  private_record = "${aws_route53_record.private.id}"
  dns_name       = "ldap.${local.az}.enron.com"
}

resource "aws_subnet" "ldap" {
  vpc_id                  = "${local.vpc_id}"
  availability_zone       = "${local.az}"
  cidr_block              = "${local.cidr}"
  map_public_ip_on_launch = true

  tags {
    Name = "ldap-subnet-${local.vpc_name}-${local.az}"
  }
}

resource "aws_route_table_association" "ldap" {
  subnet_id      = "${local.subnet_id}"
  route_table_id = "${local.rt_id}"
}

resource "aws_instance" "ldap" {
  ami                    = "${local.ami}"
  key_name               = "${local.key_name}"
  instance_type          = "t3.micro"
  subnet_id              = "${local.subnet_id}"
  vpc_security_group_ids = ["${local.sg_id}"]

  tags {
    Name = "ldap-instance-${local.vpc_name}-${local.az}"
  }
}

resource "aws_route53_record" "private" {
  zone_id = "${local.zone_id}"
  name    = "${local.dns_name}"
  type    = "A"
  ttl     = "300"
  records = ["${local.private_ip}"]
}

resource "aws_route53_record" "shortcut" {
  zone_id = "${local.zone_id}"
  name    = "ldap.enron.com"
  type    = "CNAME"
  ttl     = "300"
  records = ["${local.dns_name}"]
}
