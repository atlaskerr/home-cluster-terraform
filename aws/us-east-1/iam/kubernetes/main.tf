provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/iam/kubernetes/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_iam_policy_document" "kubernetes_master" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["ec2:*"]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["autoscaling:*"]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["elasticloadbalancing:*"]
  }
}

data "aws_iam_policy_document" "kubernetes_master_assume_role" {
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
  policy        = "${data.aws_iam_policy_document.kubernetes_master.json}"
  assume_policy = "${data.aws_iam_policy_document.kubernetes_master_assume_role.json}"
  policy_arn    = "${aws_iam_policy.kubernetes_master.arn}"
  role          = "${aws_iam_role.kubernetes_master.name}"
  profile       = "${aws_iam_instance_profile.kubernetes_master.name}"
}

resource "aws_iam_policy" "kubernetes_master" {
  name        = "kubernetes-master"
  description = "Kubernetes AWS Access"
  policy      = "${local.policy}"
}

resource "aws_iam_role" "kubernetes_master" {
  name               = "kubernetes-master"
  assume_role_policy = "${local.assume_policy}"
}

resource "aws_iam_policy_attachment" "kubernetes_master" {
  name       = "kubernetes-master-attachment"
  roles      = ["${local.role}"]
  policy_arn = "${local.policy_arn}"
}

resource "aws_iam_instance_profile" "kubernetes_master" {
  name = "kubernetes-master-profile"
  role = "${local.role}"
}

output "kubernetes_master_iam_profile" {
  value = "${local.profile}"
}
