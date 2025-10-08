output "aws_lambda_function_name" {
  value = aws_lambda_function.ebs_tag_checker.function_name
}

output "aws_lambda_function_arn" {
  value = aws_lambda_function.ebs_tag_checker.arn
}

output "aws_sqs_queue_lambda_dlq_arn" {
  value = aws_sqs_queue.lambda_dlq.arn
}