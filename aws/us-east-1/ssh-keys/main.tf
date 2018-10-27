provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "terraform-enron"
    key    = "aws/us-east-1/ssh-keys/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_key_pair" "atlas" {
  key_name   = "atlas-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0PxTgT+psZHwbfAfenCzuwYQAD7L6EeugctLk9GqeBV7N0wamDYZLwqMg+JiMT9LCzSmjGvjOfM31SGcezmXDM19adAV3EoNKryIdhUR68n7Uo2uJHPHyRWhoP89rnRMnLNiSZVGlq9vOWF0Yb21L+GkBQVN1VnTwsPB96nA7og9ZmIVRhrGj5XPP1AL22adOV6pLXklDdLFrzjZkeXhU+cDvC8o7WqIqQqVXGLdcP1azbeJrFT/nCTfKp6PHpsTjdGrjQOxPOfvy1d3vSeiPVt1pQAZhg34QeEnmgjtRoxWSVwEbVKjjv2cSIN9PYMp88lkGlvN/nB9OCHIa115d atlas@pointmicro"
}

output "atlas" {
  value = "${aws_key_pair.atlas.key_name}"
}
