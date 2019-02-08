resource "aws_ebs_volume" "prometheus" {
  availability_zone = "us-east-1c"
  type              = "gp2"
  size              = "50"

  tags {
    Name = "prometheus"
  }
}

output "prometheus_id" {
  value = "${aws_ebs_volume.prometheus.id}"
}
