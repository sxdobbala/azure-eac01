#AwsDoc-MetricListing: https://docs.aws.amazon.com/redshift/latest/mgmt/metrics-listing.html

locals {
  redshift-thresholds = "${var.thresholds["redshift"]}"
}

#Redshift Average CPU Utilization Alert.
resource "aws_cloudwatch_metric_alarm" "high_redshift_cpu_utilization" {
  count               = "${length(var.redshift_clusterIdentifiers)}"
  alarm_name          = "high_redshift_cpu_utilization_${element(var.redshift_clusterIdentifiers, count.index)}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/Redshift"
  period              = "900"
  statistic           = "Average"
  threshold           = "${local.redshift-thresholds["cpu_utilization"]}"
  alarm_description   = "High Redshift CPU utilization over last 15 minutes"
  alarm_actions       = ["${aws_sns_topic.alerts.arn}"]
  dimensions = {
    ClusterIdentifier  = "${element(var.redshift_clusterIdentifiers, count.index)}"
  }
}

#Redshift Average Percentage Disk Space Used Alert.
resource "aws_cloudwatch_metric_alarm" "low_redshift_free_disk_space" {
  count               = "${length(var.redshift_clusterIdentifiers)}"
  alarm_name          = "low_redshift_free_disk_space_${element(var.redshift_clusterIdentifiers, count.index)}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "PercentageDiskSpaceUsed"
  namespace           = "AWS/Redshift"
  period              = "900"
  statistic           = "Average"
  threshold           = "${local.redshift-thresholds["percentage_diskSpace_used"]}"
  alarm_description   = "High Redshift Disk Space Usage"
  alarm_actions       = ["${aws_sns_topic.alerts.arn}"]
  dimensions = {
    ClusterIdentifier  = "${element(var.redshift_clusterIdentifiers, count.index)}"
  }
}

