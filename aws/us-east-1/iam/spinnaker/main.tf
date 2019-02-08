provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/iam/spinnaker/terraform.tfstate"
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
  s3_arn = "${data.terraform_remote_state.s3.spinnaker_arn}"
}

data "aws_iam_policy_document" "spinnaker" {
  statement {
    effect    = "Allow"
    resources = ["${local.s3_arn}"]
    actions   = ["s3:*"]
  }

  statement {
    effect    = "Allow"
    resources = ["${local.s3_arn}/*"]
    actions   = ["s3:*"]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["*"]
  }
}

data "aws_iam_policy_document" "spinnaker_assume_role" {
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
  policy        = "${data.aws_iam_policy_document.spinnaker.json}"
  assume_policy = "${data.aws_iam_policy_document.spinnaker_assume_role.json}"
  policy_arn    = "${aws_iam_policy.spinnaker.arn}"
  role          = "${aws_iam_role.spinnaker.name}"
  profile       = "${aws_iam_instance_profile.spinnaker.name}"
}

resource "aws_iam_policy" "spinnaker" {
  name        = "spinnaker"
  description = "Spinnaker S3 Access"
  policy      = "${local.policy}"
}

resource "aws_iam_role" "spinnaker" {
  name               = "spinnaker"
  assume_role_policy = "${local.assume_policy}"
}

resource "aws_iam_policy_attachment" "spinnaker" {
  name       = "spinnaker-attachment"
  roles      = ["${local.role}"]
  policy_arn = "${local.policy_arn}"
}

resource "aws_iam_instance_profile" "spinnaker" {
  name = "spinnaker-profile"
  role = "${local.role}"
}

output "spinnaker_iam_profile" {
  value = "${local.profile}"
}
