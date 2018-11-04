provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/iam/harbor/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "s3" {
  backend = "s3"

  config {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/s3/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  s3_arn = "${data.terraform_remote_state.s3.image_registry_arn}"
}

data "aws_iam_policy_document" "harbor_registry" {
  statement {
    effect    = "Allow"
    resources = ["${local.s3_arn}"]

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["${local.s3_arn}/*"]

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload",
    ]
  }
}

data "aws_iam_policy_document" "harbor_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

locals {
  harbor_policy        = "${data.aws_iam_policy_document.harbor_registry.json}"
  harbor_assume_policy = "${data.aws_iam_policy_document.harbor_assume_role.json}"
}

resource "aws_iam_policy" "harbor_registry" {
  name        = "harbor-registry"
  description = "Harbor Registry S3 Access"
  policy      = "${local.harbor_policy}"
}

resource "aws_iam_role" "harbor_registry" {
  name               = "harbor-s3-access"
  assume_role_policy = "${local.harbor_assume_policy}"
}

resource "aws_iam_policy_attachment" "harbor_registry" {
  name       = "harbor-attachment"
  roles      = ["${aws_iam_role.harbor_registry.name}"]
  policy_arn = "${aws_iam_policy.harbor_registry.arn}"
}

resource "aws_iam_instance_profile" "harbor_registry" {
  name = "harbor-profile"
  role = "${aws_iam_role.harbor_registry.name}"
}

output "harbor_iam_profile" {
  value = "${aws_iam_instance_profile.harbor_registry.name}"
}
