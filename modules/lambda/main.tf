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

  environment {
    variables = {
      SNS_TOPIC_ARN   = var.aws_sns_topic_arn
      DEFAULT_TAG_VALUE = var.backup_frequency
    }
  }
}