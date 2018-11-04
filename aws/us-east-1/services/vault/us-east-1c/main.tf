provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/services/vault/us-east-1c/terraform.tfstate"
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

data "terraform_remote_state" "sg_vault" {
  backend = "s3"

  config {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/sg/vault/terraform.tfstate"
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
  az         = "us-east-1c"
  vpc_id     = "${data.terraform_remote_state.vpc.vpc_id}"
  vpc_name   = "${data.terraform_remote_state.vpc.name}"
  rt_id      = "${data.terraform_remote_state.vpc.rt_private_id}"
  key_name   = "${data.terraform_remote_state.ssh_keys.atlas}"
  cidr       = "${data.terraform_remote_state.cidrs.vault_c}"
  sg_id      = "${data.terraform_remote_state.sg_vault.sg_id}"
  zone_id    = "${data.terraform_remote_state.dns.private_zone_id}"
  ami        = "${data.aws_ami.centos.id}"
  subnet_id  = "${aws_subnet.vault.id}"
  private_ip = "${aws_instance.vault.private_ip}"
  zone_name  = "${data.terraform_remote_state.dns.private_zone_domain_name}"
  dns_name   = "vault.${local.zone_name}"
}

resource "aws_subnet" "vault" {
  vpc_id                  = "${local.vpc_id}"
  availability_zone       = "${local.az}"
  cidr_block              = "${local.cidr}"
  map_public_ip_on_launch = false

  tags {
    Name = "vault-subnet-${local.vpc_name}-${local.az}"
  }
}

resource "aws_route_table_association" "vault" {
  subnet_id      = "${local.subnet_id}"
  route_table_id = "${local.rt_id}"
}

resource "aws_instance" "vault" {
  ami                    = "${local.ami}"
  key_name               = "${local.key_name}"
  instance_type          = "t3.micro"
  subnet_id              = "${local.subnet_id}"
  vpc_security_group_ids = ["${local.sg_id}"]

  tags {
    Name = "vault-instance-${local.vpc_name}-${local.az}"
  }
}

resource "aws_route53_record" "vault" {
  zone_id = "${local.zone_id}"
  name    = "${local.dns_name}"
  type    = "A"
  ttl     = "300"
  records = ["${local.private_ip}"]
}
