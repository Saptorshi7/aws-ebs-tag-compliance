output "aws_kms_key_sns_key_arn" {
  value = aws_kms_key.sns_key.arn
}

output "aws_kms_key_lambda_key_arn" {
  value = aws_kms_key.lambda_env_key.arn
}