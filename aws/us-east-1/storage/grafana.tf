resource "aws_ebs_volume" "grafana_db" {
  availability_zone = "us-east-1c"
  type              = "gp2"
  size              = "10"

  tags {
    Name = "grafana-postgres-data"
  }
}

output "grafana_db_id" {
  value = "${aws_ebs_volume.grafana_db.id}"
}
