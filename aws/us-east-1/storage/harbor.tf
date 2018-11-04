resource "aws_ebs_volume" "harbor_db" {
  availability_zone = "us-east-1c"
  type              = "gp2"
  size              = "10"

  tags {
    Name = "harbor-db"
  }
}

output "harbor_db_id" {
  value = "${aws_ebs_volume.harbor_db.id}"
}
