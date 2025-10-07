provider "aws" {
  region = "us-east-1" # change as needed
}

# SNS Topic for Alerts
module "sns" {
  source              = "./modules/sns"

  aws_sns_topic_name     = var.aws_sns_topic_name
  aws_sns_topic_subscription_endpoint = var.aws_sns_topic_subscription_endpoint
}

# IAM Role + Policy for Lambda
module "iam" {
  source              = "./modules/iam"

  aws_iam_role_name = var.aws_iam_role_name
  aws_iam_role_policy_name = var.aws_iam_role_policy_name
  aws_sns_topic_arn = module.sns.aws_sns_topic_arn
}

# Lambda Function
module "lambda" {
  source              = "./modules/lambda"

  name = var.lambda_name
  iam_role = module.iam.aws_iam_role_arn
  runtime = var.lambda_runtime
  aws_sns_topic_arn = module.sns.aws_sns_topic_arn
  backup_frequency = var.backup_frequency
}

# EventBridge Rule
module "eventbridge" {
  source              = "./modules/eventbridge"

  name = var.eventbridge_name
  aws_lambda_function_arn = module.lambda.aws_lambda_function_arn
  aws_lambda_function_name = module.lambda.aws_lambda_function_name
}