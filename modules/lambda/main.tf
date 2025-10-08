resource "aws_sqs_queue" "lambda_dlq" {
  name = "${var.name}-dlq"
}

resource "aws_signer_signing_profile" "dev" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  name_prefix = "dev_lambda_"

  tags = {
    Environment = "development"
  }
}

resource "aws_lambda_code_signing_config" "lambda_signing" {
  description = "Code signing config for EBS tag checker"
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.dev.version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Warn" # Allow deployments but log validation failures
  }
}

############################
# Lambda Function
############################
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "ebs_tag_checker" {
  function_name = var.name
  role          = var.iam_role
  handler       = "lambda_function.lambda_handler"
  runtime       = var.runtime

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  code_signing_config_arn = aws_lambda_code_signing_config.lambda_signing.arn
  reserved_concurrent_executions = 10
  kms_key_arn = var.kms_key_arn

  tracing_config {
    mode = "Active"
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  environment {
    variables = {
      SNS_TOPIC_ARN   = var.aws_sns_topic_arn
      DEFAULT_TAG_VALUE = var.backup_frequency
    }
  }
}