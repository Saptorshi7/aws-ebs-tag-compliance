provider "aws" {
  region = "us-east-1" # change as needed
}

############################
# SNS Topic for Alerts
############################
resource "aws_sns_topic" "ebs_alerts" {
  name = "EBSMissingTagAlerts"
}

resource "aws_sns_topic_subscription" "security_email" {
  topic_arn = aws_sns_topic.ebs_alerts.arn
  protocol  = "email"
  endpoint  = "security-team@example.com" # change to your email
}

############################
# IAM Role + Policy for Lambda
############################
resource "aws_iam_role" "lambda_role" {
  name = "EBSLambdaRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "EBSLambdaPolicy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["ec2:DescribeVolumes", "ec2:CreateTags"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["sns:Publish"],
        Resource = aws_sns_topic.ebs_alerts.arn
      },
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
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
  function_name = "EBSBackupFrequencyChecker"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path)

  environment {
    variables = {
      SNS_TOPIC_ARN   = aws_sns_topic.ebs_alerts.arn
      DEFAULT_TAG_VALUE = "Daily"
    }
  }
}

############################
# EventBridge Rule
############################
resource "aws_cloudwatch_event_rule" "ebs_create_volume" {
  name        = "EBSCreateVolumeRule"
  description = "Triggers on EBS CreateVolume events"
  event_pattern = jsonencode({
    "source"      : ["aws.ec2"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail"      : {
      "eventSource": ["ec2.amazonaws.com"],
      "eventName"  : ["CreateVolume"]
    }
  })
}

resource "aws_cloudwatch_event_target" "send_to_lambda" {
  rule      = aws_cloudwatch_event_rule.ebs_create_volume.name
  target_id = "EBSLambda"
  arn       = aws_lambda_function.ebs_tag_checker.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ebs_tag_checker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ebs_create_volume.arn
}
