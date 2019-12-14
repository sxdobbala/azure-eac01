#AwsDoc-MetricListing: https://docs.aws.amazon.com/lambda/latest/dg/monitoring-functions-metrics.html
# locals {
#   lambda-metrics = {
#     ErrorsThreshold    = "0"
#     ThrottlesThreshold = "0"
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
#   alarm_name          = "lambda_errors"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "Errors"
#   namespace           = "AWS/Lambda"
#   period              = "60"
#   statistic           = "Sum"
#   threshold           = "${local.lambda-metrics["ErrorsThreshold"]}"
#   alarm_description   = "Lambda function is erroring on invocations"
#   alarm_actions       = ["${aws_sns_topic.alerts.arn}"]
#   dimensions = {
#     FunctionName = "${var.lambda_name}"
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
#   alarm_name          = "lambda_throttles"
#   comparison_operator = "GreaterThanThreshold"
#   evaluation_periods  = "1"
#   metric_name         = "Throttles"
#   namespace           = "AWS/Lambda"
#   period              = "60"
#   statistic           = "Sum"
#   threshold           = "${local.lambda-metrics["ThrottlesThreshold"]}"
#   alarm_description   = "Average number of throttled invocations higher than threshold"
#   alarm_actions       = ["${aws_sns_topic.alerts.arn}"]
#   dimensions = {
#     FunctionName = "${var.lambda_name}"
#   }
# }

