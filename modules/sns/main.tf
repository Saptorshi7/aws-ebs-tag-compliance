############################
# SNS Topic for Alerts
############################
resource "aws_sns_topic" "ebs_alerts" {
  name = var.aws_sns_topic_name
}

resource "aws_sns_topic_subscription" "security_email" {
  topic_arn = aws_sns_topic.ebs_alerts.arn
  protocol  = "email"
  endpoint  = var.aws_sns_topic_subscription_endpoint
}