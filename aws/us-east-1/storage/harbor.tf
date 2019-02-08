resource "aws_ebs_volume" "harbor_db" {
  availability_zone = "us-east-1c"
  type              = "gp2"
  size              = "10"

  tags {
    Name = "harbor-db"
  }
}

resource "aws_ebs_volume" "image_storage" {
  availability_zone = "us-east-1c"
  type              = "gp2"
  size              = "10"

  tags {
    Name = "image_storage"
  }
}

output "harbor_db_id" {
  value = "${aws_ebs_volume.harbor_db.id}"
}

output "image_storage_id" {
  value = "${aws_ebs_volume.image_storage.id}"
}
