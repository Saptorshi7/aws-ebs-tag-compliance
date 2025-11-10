terraform {
  backend "s3" {
    bucket         = "spl-terraform"
    key            = "aws-ebs-tag-compliance/terraform.tfstate"
    region         = "us-east-1"
  }
}