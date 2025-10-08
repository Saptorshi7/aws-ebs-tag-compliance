provider "aws" {
  region = var.aws_region
}

# SNS Topic for Alerts
module "sns" {
  source              = "./modules/sns"

  aws_sns_topic_name     = var.aws_sns_topic_name
  aws_sns_topic_subscription_endpoint = var.aws_sns_topic_subscription_endpoint
  kms_master_key_id = module.kms.aws_kms_key_sns_key_arn
}

# IAM Role + Policy for Lambda
module "iam" {
  source              = "./modules/iam"

  aws_iam_role_name = var.aws_iam_role_name
  aws_iam_role_policy_name = var.aws_iam_role_policy_name
  aws_sns_topic_arn = module.sns.aws_sns_topic_arn
  aws_sqs_queue_arn = module.lambda.aws_sqs_queue_lambda_dlq_arn
}

# Lambda Function
module "lambda" {
  source              = "./modules/lambda"

  name = var.lambda_name
  iam_role = module.iam.aws_iam_role_arn
  runtime = var.lambda_runtime
  aws_sns_topic_arn = module.sns.aws_sns_topic_arn
  backup_frequency = var.backup_frequency
  kms_key_arn = module.kms.aws_kms_key_lambda_key_arn
}

# EventBridge Rule
module "eventbridge" {
  source              = "./modules/eventbridge"

  name = var.eventbridge_name
  aws_lambda_function_arn = module.lambda.aws_lambda_function_arn
  aws_lambda_function_name = module.lambda.aws_lambda_function_name
}

module "kms" {
  source              = "./modules/kms"

}