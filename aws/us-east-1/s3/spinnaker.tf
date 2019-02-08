resource "aws_s3_bucket" "spinnaker" {
  bucket = "enron-spinnaker"
  acl    = "private"

  tags {
    Name = "spinnaker-storage-s3-enron"
  }
}

output "spinnaker_arn" {
  value = "${aws_s3_bucket.spinnaker.arn}"
}
