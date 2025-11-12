terraform {
  backend "s3" {
    bucket         = "spl-tf-bucket"
    key            = "aws-ebs-tag-compliance/terraform.tfstate"
    region         = "us-east-1"
  }
}