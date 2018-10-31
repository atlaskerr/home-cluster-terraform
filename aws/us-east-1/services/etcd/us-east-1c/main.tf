provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/services/etcd/us-east-1c/terraform.tfstate"
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

data "terraform_remote_state" "sg_etcd" {
  backend = "s3"

  config {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/sg/etcd/terraform.tfstate"
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
  az       = "us-east-1c"
  vpc_id   = "${data.terraform_remote_state.vpc.vpc_id}"
  vpc_name = "${data.terraform_remote_state.vpc.name}"
  rt_id    = "${data.terraform_remote_state.vpc.rt_private_id}"
  key_name = "${data.terraform_remote_state.ssh_keys.atlas}"
  cidr     = "${data.terraform_remote_state.cidrs.etcd_c}"
  sg_id    = "${data.terraform_remote_state.sg_etcd.sg_id}"
  ami      = "${data.aws_ami.centos.id}"
  zone_id       = "${data.terraform_remote_state.dns.private_zone_id}"
  zone_name       = "${data.terraform_remote_state.dns.private_zone_domain_name}"

  dns_base_name = "etcd.${local.zone_name}"
  subnet_id     = "${aws_subnet.etcd.id}"

  etcd1_id         = "${aws_instance.etcd1.id}"
  etcd1_ip         = "${aws_instance.etcd1.private_ip}"
  etcd1_vol        = "${data.terraform_remote_state.storage.etcd1_vol_id}"
  etcd1_dns_record = "${aws_route53_record.etcd1.name}"

  etcd2_id         = "${aws_instance.etcd2.id}"
  etcd2_ip         = "${aws_instance.etcd2.private_ip}"
  etcd2_vol        = "${data.terraform_remote_state.storage.etcd2_vol_id}"
  etcd2_dns_record = "${aws_route53_record.etcd2.name}"

  etcd3_id         = "${aws_instance.etcd3.id}"
  etcd3_ip         = "${aws_instance.etcd3.private_ip}"
  etcd3_vol        = "${data.terraform_remote_state.storage.etcd3_vol_id}"
  etcd3_dns_record = "${aws_route53_record.etcd3.name}"
}

resource "aws_subnet" "etcd" {
  vpc_id                  = "${local.vpc_id}"
  availability_zone       = "${local.az}"
  cidr_block              = "${local.cidr}"
  map_public_ip_on_launch = false

  tags {
    Name = "etcd-subnet-${local.vpc_name}-${local.az}"
  }
}

resource "aws_route_table_association" "etcd" {
  subnet_id      = "${local.subnet_id}"
  route_table_id = "${local.rt_id}"
}

resource "aws_instance" "etcd1" {
  ami                    = "${local.ami}"
  key_name               = "${local.key_name}"
  instance_type          = "t3.micro"
  subnet_id              = "${local.subnet_id}"
  vpc_security_group_ids = ["${local.sg_id}"]

  tags {
    Name = "etcd1-instance-${local.vpc_name}-${local.az}"
  }
}

resource "aws_instance" "etcd2" {
  ami                    = "${local.ami}"
  key_name               = "${local.key_name}"
  instance_type          = "t3.micro"
  subnet_id              = "${local.subnet_id}"
  vpc_security_group_ids = ["${local.sg_id}"]

  tags {
    Name = "etcd2-instance-${local.vpc_name}-${local.az}"
  }
}

resource "aws_instance" "etcd3" {
  ami                    = "${local.ami}"
  key_name               = "${local.key_name}"
  instance_type          = "t3.micro"
  subnet_id              = "${local.subnet_id}"
  vpc_security_group_ids = ["${local.sg_id}"]

  tags {
    Name = "etcd3-instance-${local.vpc_name}-${local.az}"
  }
}

resource "aws_volume_attachment" "etcd1" {
  device_name = "/dev/sdd"
  instance_id = "${local.etcd1_id}"
  volume_id   = "${local.etcd1_vol}"
}

resource "aws_volume_attachment" "etcd2" {
  device_name = "/dev/sdd"
  instance_id = "${local.etcd2_id}"
  volume_id   = "${local.etcd2_vol}"
}

resource "aws_volume_attachment" "etcd3" {
  device_name = "/dev/sdd"
  instance_id = "${local.etcd3_id}"
  volume_id   = "${local.etcd3_vol}"
}


resource "aws_route53_record" "etcd1" {
  zone_id = "${local.zone_id}"
  name    = "node-1.${local.dns_base_name}"
  type    = "A"
  ttl     = "300"
  records = ["${local.etcd1_ip}"]
}

resource "aws_route53_record" "etcd2" {
  zone_id = "${local.zone_id}"
  name    = "node-2.${local.dns_base_name}"
  type    = "A"
  ttl     = "300"
  records = ["${local.etcd2_ip}"]
}

resource "aws_route53_record" "etcd3" {
  zone_id = "${local.zone_id}"
  name    = "node-3.${local.dns_base_name}"
  type    = "A"
  ttl     = "300"
  records = ["${local.etcd3_ip}"]
}

resource "aws_route53_record" "etcd_servers" {
  zone_id = "${local.zone_id}"
  name    = "_etcd-server-ssl._tcp.${local.zone_name}"
  type    = "SRV"
  ttl     = "300"

  records = [
    "0 40 2380 ${local.etcd1_dns_record}",
    "0 40 2380 ${local.etcd2_dns_record}",
    "0 20 2380 ${local.etcd3_dns_record}"
  ]
}

resource "aws_route53_record" "etcd_clients" {
  zone_id = "${local.zone_id}"
  name    = "_etcd-client-ssl._tcp.${local.zone_name}"
  type    = "SRV"
  ttl     = "300"

  records = [
    "0 40 2379 ${local.etcd1_dns_record}",
    "0 40 2379 ${local.etcd2_dns_record}",
    "0 20 2379 ${local.etcd3_dns_record}"
  ]
}
