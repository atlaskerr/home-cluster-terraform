resource "aws_ebs_volume" "etcd1" {
  availability_zone = "us-east-1c"
  type              = "gp2"
  size              = "80"

  tags {
    Name = "Etcd Node 1 Storage"
  }
}

resource "aws_ebs_volume" "etcd2" {
  availability_zone = "us-east-1c"
  type              = "gp2"
  size              = "80"

  tags {
    Name = "Etcd Node 2 Storage"
  }
}

resource "aws_ebs_volume" "etcd3" {
  availability_zone = "us-east-1c"
  type              = "gp2"
  size              = "80"

  tags {
    Name = "Etcd Node 3 Storage"
  }
}

output "etcd1_vol_id" {
  value = "${aws_ebs_volume.etcd1.id}"
}
output "etcd2_vol_id" {
  value = "${aws_ebs_volume.etcd2.id}"
}
output "etcd3_vol_id" {
  value = "${aws_ebs_volume.etcd3.id}"
}
