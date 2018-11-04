resource "aws_ebs_volume" "gitea_db" {
  availability_zone = "us-east-1c"
  type              = "gp2"
  size              = "5"

  tags {
    Name = "gitea-postgres-data"
  }
}

resource "aws_ebs_volume" "gitea_repo" {
  availability_zone = "us-east-1c"
  type              = "gp2"
  size              = "50"

  tags {
    Name = "gitea-repo-storage"
  }
}

output "gitea_db_id" {
  value = "${aws_ebs_volume.gitea_db.id}"
}

output "gitea_repo_id" {
  value = "${aws_ebs_volume.gitea_repo.id}"
}
