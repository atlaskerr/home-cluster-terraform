provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/services/efk-stack/us-east-1c/terraform.tfstate"
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

data "terraform_remote_state" "sg_efk" {
  backend = "s3"

  config {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/sg/efk-stack/terraform.tfstate"
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
  ami       = "${data.aws_ami.centos.id}"
  zone_id   = "${data.terraform_remote_state.dns.private_zone_id}"
  zone_name = "${data.terraform_remote_state.dns.private_zone_domain_name}"

  elasticsearch_cidr        = "${data.terraform_remote_state.cidrs.efk_elasticsearch_c}"
  elasticsearch_sg_id       = "${data.terraform_remote_state.sg_efk.elasticsearch_sg_id}"
  elasticsearch_subnet_id   = "${aws_subnet.elasticsearch.id}"
  elasticsearch_dns_name    = "elasticsearch.logs.${local.zone_name}"
  elasticsearch_ip          = "${aws_instance.elasticsearch.private_ip}"
  elasticsearch_instance_id = "${aws_instance.elasticsearch.id}"
  elasticsearch_data        = "${data.terraform_remote_state.storage.efk_elasticsearch_id}"
}

resource "aws_subnet" "elasticsearch" {
  vpc_id                  = "${local.vpc_id}"
  availability_zone       = "us-east-1c"
  cidr_block              = "${local.elasticsearch_cidr}"
  map_public_ip_on_launch = false

  tags {
    Name = "elk-elasticsearch-subnet-${local.vpc_name}-${local.az}"
  }
}

resource "aws_route_table_association" "elasticsearch" {
  subnet_id      = "${aws_subnet.elasticsearch.id}"
  route_table_id = "${local.rt_id}"
}

resource "aws_instance" "elasticsearch" {
  ami                    = "${local.ami}"
  key_name               = "${local.key_name}"
  instance_type          = "m5.large"
  subnet_id              = "${local.elasticsearch_subnet_id}"
  vpc_security_group_ids = ["${local.elasticsearch_sg_id}"]

  tags {
    Name = "elasticsearch-instance-${local.vpc_name}-${local.az}"
  }
}

resource "aws_volume_attachment" "elasticsearch" {
  device_name = "/dev/sdg"
  instance_id = "${local.elasticsearch_instance_id}"
  volume_id   = "${local.elasticsearch_data}"
}

resource "aws_route53_record" "elasticsearch" {
  zone_id = "${local.zone_id}"
  name    = "${local.elasticsearch_dns_name}"
  type    = "A"
  ttl     = "300"
  records = ["${local.elasticsearch_ip}"]
}
