#AwsDoc-MetricListing: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/MonitoringOverview.html#monitoring-cloudwatch

locals {
  rds-thresholds = "${var.thresholds["rds"]}"
}

#RDS Burst Balance Alert.
resource "aws_cloudwatch_metric_alarm" "low_rds_burst_balance" {
  count               = "${length(var.rds_instanceIds)}"
  alarm_name          = "low_rds_burst_balance_${element(var.rds_instanceIds, count.index)}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BurstBalance"
  namespace           = "AWS/RDS"
  period              = "600"
  statistic           = "Average"
  threshold           = "${local.rds-thresholds["burst_balance"]}"
  alarm_description   = "Low RDS Burst Balance over last 15 mins"
  alarm_actions       = ["${aws_sns_topic.alerts.arn}"]
  dimensions = {
    DBInstanceIdentifier = "${element(var.rds_instanceIds, count.index)}"
  }
}

#RDS CPU Utilization Alert.
resource "aws_cloudwatch_metric_alarm" "high_rds_cpu_utilization" {
  count               = "${length(var.rds_instanceIds)}"
  alarm_name          = "high_rds_cpu_utilization_${element(var.rds_instanceIds, count.index)}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "900"
  statistic           = "Average"
  threshold           = "${local.rds-thresholds["cpu_utilization"]}"
  alarm_description   = "High RDS CPU utilization over last 15 minutes"
  alarm_actions       = ["${aws_sns_topic.alerts.arn}"]
  dimensions = {
    DBInstanceIdentifier = "${element(var.rds_instanceIds, count.index)}"
  }
}

#TODO:
# resource "aws_cloudwatch_metric_alarm" "high_disk_queue_depth" {
#   alarm_name          = ""
#   comparison_operator = ""
#   evaluation_periods  = ""
#   metric_name         = ""
#   namespace           = ""
#   period              = ""
#   statistic           = ""
#   threshold           = ""
#   alarm_description   = ""
#   alarm_actions       = [""]


#   dimensions = {
#     DBInstanceIdentifier = "${var.db_instance_id}"
#   }
# }


# resource "aws_cloudwatch_metric_alarm" "low_freeable_memory" {
#   alarm_name          = ""
#   comparison_operator = ""
#   evaluation_periods  = ""
#   metric_name         = ""
#   namespace           = ""
#   period              = ""
#   statistic           = ""
#   threshold           = ""
#   alarm_description   = ""
#   alarm_actions       = [""]


#   dimensions = {
#     DBInstanceIdentifier = "${var.db_instance_id}"
#   }
# }


# resource "aws_cloudwatch_metric_alarm" "low_free_storage_space" {
#   alarm_name          = ""
#   comparison_operator = ""
#   evaluation_periods  = ""
#   metric_name         = ""
#   namespace           = ""
#   period              = ""
#   statistic           = ""
#   threshold           = ""
#   alarm_description   = ""
#   alarm_actions       = [""]


#   dimensions = {
#     DBInstanceIdentifier = "${var.db_instance_id}"
#   }
# }


# resource "aws_cloudwatch_metric_alarm" "high_swap_usage" {
#   alarm_name          = ""
#   comparison_operator = ""
#   evaluation_periods  = ""
#   metric_name         = ""
#   namespace           = ""
#   period              = ""
#   statistic           = ""
#   threshold           = ""
#   alarm_description   = ""
#   alarm_actions       = [""]


#   dimensions = {
#     DBInstanceIdentifier = "${var.db_instance_id}"
#   }
#}

