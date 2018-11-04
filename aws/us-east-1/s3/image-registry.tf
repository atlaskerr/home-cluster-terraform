resource "aws_s3_bucket" "container_image_registry" {
  bucket = "enron-container-images"
  acl    = "private"

  tags {
    Name = "image-registry-storage-s3-enron"
  }
}

output "image_registry_arn" {
  value = "${aws_s3_bucket.container_image_registry.arn}"
}
