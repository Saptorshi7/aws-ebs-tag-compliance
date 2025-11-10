############################
# EventBridge Rule
############################
resource "aws_cloudwatch_event_rule" "ebs_create_volume" {
  name        = var.name
  description = "Triggers on EBS CreateVolume events"
  event_pattern = jsonencode({
  "source": ["aws.ec2"],
  "detail-type": ["EBS Volume Notification"],
  "detail": {
    "event": ["createVolume"]
  }
})
}

resource "aws_cloudwatch_event_target" "send_to_lambda" {
  rule      = aws_cloudwatch_event_rule.ebs_create_volume.name
  target_id = "EBSLambda"
  arn       = var.aws_lambda_function_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.aws_lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ebs_create_volume.arn
}