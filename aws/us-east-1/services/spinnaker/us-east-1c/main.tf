provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/services/spinnaker/us-east-1c/terraform.tfstate"
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

data "terraform_remote_state" "cidrs" {
  backend = "s3"

  config {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/cidrs/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "sg_spinnaker" {
  backend = "s3"

  config {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/sg/spinnaker/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"

  config {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/iam/spinnaker/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

locals {
  az        = "us-east-1c"
  ami       = "${data.aws_ami.ubuntu.id}"
  vpc_id    = "${data.terraform_remote_state.vpc.vpc_id}"
  vpc_name  = "${data.terraform_remote_state.vpc.name}"
  rt_id     = "${data.terraform_remote_state.vpc.rt_private_id}"
  key_name  = "${data.terraform_remote_state.ssh_keys.atlas}"
  cidr      = "${data.terraform_remote_state.cidrs.spinnaker_c}"
  sg_id     = "${data.terraform_remote_state.sg_spinnaker.sg_id}"
  zone_id   = "${data.terraform_remote_state.dns.private_zone_id}"
  zone_name = "${data.terraform_remote_state.dns.private_zone_domain_name}"
  iam_id    = "${data.terraform_remote_state.iam.spinnaker_iam_profile}"

  subnet_id   = "${aws_subnet.spinnaker.id}"
  ip          = "${aws_instance.spinnaker.private_ip}"
  instance_id = "${aws_instance.spinnaker.id}"

  dns_name = "deploy.${local.zone_name}"
}

resource "aws_subnet" "spinnaker" {
  vpc_id                  = "${local.vpc_id}"
  availability_zone       = "us-east-1c"
  cidr_block              = "${local.cidr}"
  map_public_ip_on_launch = false

  tags {
    Name = "spinnaker-subnet-${local.vpc_name}-${local.az}"
  }
}

resource "aws_route_table_association" "spinnaker" {
  subnet_id      = "${local.subnet_id}"
  route_table_id = "${local.rt_id}"
}

resource "aws_instance" "spinnaker" {
  ami                    = "${local.ami}"
  key_name               = "${local.key_name}"
  instance_type          = "m5.large"
  subnet_id              = "${local.subnet_id}"
  vpc_security_group_ids = ["${local.sg_id}"]
  iam_instance_profile   = "${local.iam_id}"

  tags {
    Name = "spinnaker-instance-${local.vpc_name}-${local.az}"
  }
}

resource "aws_route53_record" "spinnaker" {
  zone_id = "${local.zone_id}"
  name    = "${local.dns_name}"
  type    = "A"
  ttl     = "300"
  records = ["${local.ip}"]
}
