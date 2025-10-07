variable "aws_sns_topic_name" {
    type = string
    default = "EBSMissingTagAlerts"
}

variable "aws_sns_topic_subscription_endpoint" {
    type = string
    default = "saptorshi.pal@atos.net"
}

variable "aws_iam_role_policy_name" {
    type = string
    default = "EBSLambdaPolicy"
}


variable "aws_iam_role_name" {
    type = string
    default = "EBSLambdaRole"
}

variable "lambda_name" {
    type = string
    default = "EBSBackupFrequencyChecker"
}

variable "lambda_runtime" {
    type = string
    default = "python3.9"
}

variable "backup_frequency" {
    type = string
    default = "Daily"
}

variable "eventbridge_name" {
    type = string
    default = "EBSCreateVolumeRule"
}