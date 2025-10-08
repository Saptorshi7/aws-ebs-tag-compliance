data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

############################
# IAM Role + Policy for Lambda
############################
resource "aws_iam_role" "lambda_role" {
  name = var.aws_iam_role_name
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
  name = var.aws_iam_role_policy_name
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["ec2:DescribeVolumes"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["ec2:CreateTags"],
        Resource = "arn:aws:ec2:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:volume/*"
      },
      {
        Effect   = "Allow",
        Action   = ["sns:Publish"],
        Resource = var.aws_sns_topic_arn
      },
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "sqs:SendMessage"
        ],
        Resource = var.aws_sqs_queue_arn
      }
    ]
  })
}
