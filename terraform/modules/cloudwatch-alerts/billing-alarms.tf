#NOTE: Uncomment this file after the terraform version update to (12.xx). With the current terraform version, this resource is causing more problems than it is helping. Having this in might lead to potential Jenkins Build fail.
# Have created manual budgets and alerts to monitor via Cost Explorer Console.

# locals {
#   cost-thresholds = "${var.thresholds["cost"]}"
# }
# data "aws_caller_identity" "current" {}

# resource "aws_budgets_budget" "ec2" {
#   name              = "budget-ec2-monthly"
#   budget_type       = "COST"
#   limit_amount      = "${local.cost-thresholds["ec2_budget"]}"
#   limit_unit        = "USD"
#   time_period_start = "2019-06-01_00:00"
#   time_unit         = "MONTHLY"

#   cost_filters = {
#     Service = "Amazon Elastic Compute Cloud - Compute"
#   }

#  #In order for this to work - need to upgrade the terraform version
#   # notification {
#   #   comparison_operator        = "GREATER_THAN"
#   #   threshold                  = 90
#   #   threshold_type             = "PERCENTAGE"
#   #   notification_type          = "ACTUAL"
#   #   subscriber_sns_topic_arns  = ["${aws_sns_topic.alerts.arn}"]
#   # }
# }

# resource "aws_budgets_budget" "redshift" {
#   name              = "budget-redshift-monthly"
#   budget_type       = "COST"
#   limit_amount      = "${local.cost-thresholds["redshift_budget"]}"
#   limit_unit        = "USD"
#   time_period_start = "2019-06-01_00:00"
#   time_unit         = "MONTHLY"

#   cost_filters = {
#     Service = "Amazon Redshift"
#   }

# #In order for this to work - need to upgrade the terraform version
#   # notification {
#   #   comparison_operator        = "GREATER_THAN"
#   #   threshold                  = 90
#   #   threshold_type             = "PERCENTAGE"
#   #   notification_type          = "ACTUAL"
#   #   subscriber_sns_topic_arns  = ["${aws_sns_topic.alerts.arn}"]
#   # }
# }

# resource "aws_budgets_budget" "rds" {
#   name              = "budget-rds-monthly"
#   budget_type       = "COST"
#   limit_amount      = "${local.cost-thresholds["rds_budget"]}"
#   limit_unit        = "USD"
#   time_period_start = "2019-06-01_00:00"
#   time_unit         = "MONTHLY"

#   cost_filters = {
#     Service = "Amazon Relational Database Service"
#   }

# #In order for this to work - need to upgrade the terraform version
#   # notification {
#   #   comparison_operator        = "GREATER_THAN"
#   #   threshold                  = 90
#   #   threshold_type             = "PERCENTAGE"
#   #   notification_type          = "ACTUAL"
#   #   subscriber_sns_topic_arns  = ["${aws_sns_topic.alerts.arn}"]
#   # }
# }