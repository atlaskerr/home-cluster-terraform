resource "aws_ebs_volume" "efk_elasticsearch" {
  availability_zone = "us-east-1c"
  type              = "gp2"
  size              = "100"

  tags {
    Name = "efk-elasticsearch-storage"
  }
}

output "efk_elasticsearch_id" {
  value = "${aws_ebs_volume.efk_elasticsearch.id}"
}
