resource "aws_ebs_volume" "dex_db" {
  availability_zone = "us-east-1c"
  type              = "gp2"
  size              = "5"

  tags {
    Name = "dex-postgres-data"
  }
}

output "dex_db_id" {
  value = "${aws_ebs_volume.dex_db.id}"
}
