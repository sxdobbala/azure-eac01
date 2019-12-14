#AwsDoc-MetricListing: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/viewing_metrics_with_cloudwatch.html

locals {
  ec2-thresholds = "${var.thresholds["ec2"]}"
}

#EC2 CPU Utilization Alert for all instances
resource "aws_cloudwatch_metric_alarm" "high_ec2_cpu_utilization" {
  count               = "${length(var.ec2_instanceIds)}"
  alarm_name          = "high_ec2_cpu_utilization_${element(var.ec2_instanceIds, count.index)}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "900"
  statistic           = "Average"
  threshold           = "${local.ec2-thresholds["cpu_utilization"]}"
  alarm_description   = "High EC2 CPU utilization over last 15 minutes"
  alarm_actions       = ["${aws_sns_topic.alerts.arn}"]

  dimensions = {
    InstanceId = "${element(var.ec2_instanceIds, count.index)}"
  }
}

resource "aws_cloudwatch_metric_alarm" "health" {
  count               = "${length(var.ec2_instanceIds)}"
  alarm_name          = "ec2_health_alarm_${element(var.ec2_instanceIds, count.index)}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Maximum"
  threshold           = "1"
  alarm_description   = "Unhealthy EC2 Instance"
  alarm_actions       = ["${aws_sns_topic.alerts.arn}"]

  dimensions = {
    InstanceId = "${element(var.ec2_instanceIds, count.index)}"
  }
}
#TODO: Disk Space Alerts -- no metric in cloudwatch to get this
#TODO: Memory Alerts
#Example in conjuction with Scaling Policies: https://www.terraform.io/docs/providers/aws/r/cloudwatch_metric_alarm.html

