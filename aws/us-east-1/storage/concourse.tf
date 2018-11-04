resource "aws_ebs_volume" "concourse_worker1" {
  availability_zone = "us-east-1c"
  type              = "gp2"
  size              = "50"

  tags {
    Name = "concourse-worker-dir"
  }
}

resource "aws_ebs_volume" "concourse_db" {
  availability_zone = "us-east-1c"
  type              = "gp2"
  size              = "10"

  tags {
    Name = "concourse-db"
  }
}

output "concourse_worker1_id" {
  value = "${aws_ebs_volume.concourse_worker1.id}"
}

output "concourse_db_id" {
  value = "${aws_ebs_volume.concourse_db.id}"
}
