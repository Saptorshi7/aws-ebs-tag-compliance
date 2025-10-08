resource "aws_kms_key" "lambda_env_key" {
  description = "KMS key for Lambda environment variable encryption"
  enable_key_rotation = true
}

resource "aws_kms_key" "sns_key" {
  description = "KMS key for SNS encryption"
  enable_key_rotation = true
}