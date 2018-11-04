provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/services/harbor/us-east-1c/terraform.tfstate"
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

data "terraform_remote_state" "sg_harbor" {
  backend = "s3"

  config {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/sg/harbor/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "storage" {
  backend = "s3"

  config {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/storage/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"

  config {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/iam/harbor/terraform.tfstate"
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
  vpc_id    = "${data.terraform_remote_state.vpc.vpc_id}"
  vpc_name  = "${data.terraform_remote_state.vpc.name}"
  rt_id     = "${data.terraform_remote_state.vpc.rt_private_id}"
  key_name  = "${data.terraform_remote_state.ssh_keys.atlas}"
  cidr      = "${data.terraform_remote_state.cidrs.harbor_c}"
  sg_id     = "${data.terraform_remote_state.sg_harbor.sg_id}"
  ami       = "${data.aws_ami.centos.id}"
  zone_id   = "${data.terraform_remote_state.dns.private_zone_id}"
  zone_name = "${data.terraform_remote_state.dns.private_zone_domain_name}"
  iam_id    = "${data.terraform_remote_state.iam.harbor_iam_profile}"

  subnet_id   = "${aws_subnet.harbor.id}"
  ip          = "${aws_instance.harbor.private_ip}"
  instance_id = "${aws_instance.harbor.id}"
  harbor_db   = "${data.terraform_remote_state.storage.harbor_db_id}"

  dns_name = "img.${local.zone_name}"
}

resource "aws_subnet" "harbor" {
  vpc_id                  = "${local.vpc_id}"
  availability_zone       = "us-east-1c"
  cidr_block              = "${local.cidr}"
  map_public_ip_on_launch = false

  tags {
    Name = "harbor-subnet-${local.vpc_name}-${local.az}"
  }
}

resource "aws_route_table_association" "harbor" {
  subnet_id      = "${local.subnet_id}"
  route_table_id = "${local.rt_id}"
}

resource "aws_instance" "harbor" {
  ami                    = "${local.ami}"
  key_name               = "${local.key_name}"
  instance_type          = "t3.medium"
  subnet_id              = "${local.subnet_id}"
  vpc_security_group_ids = ["${local.sg_id}"]
  iam_instance_profile   = "${local.iam_id}"

  tags {
    Name = "harbor-instance-${local.vpc_name}-${local.az}"
  }
}

resource "aws_volume_attachment" "harbor_db" {
  device_name = "/dev/sdf"
  instance_id = "${local.instance_id}"
  volume_id   = "${local.harbor_db}"
}

resource "aws_route53_record" "harbor" {
  zone_id = "${local.zone_id}"
  name    = "${local.dns_name}"
  type    = "A"
  ttl     = "300"
  records = ["${local.ip}"]
}
