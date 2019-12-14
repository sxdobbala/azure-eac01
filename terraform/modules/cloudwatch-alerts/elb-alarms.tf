locals {
  elb-thresholds = "${var.thresholds["load_balancer"]}"
}

resource "aws_cloudwatch_metric_alarm" "ELB_UnHealthyHostCount" {
  count               = "${length(var.load_balancers)}"
  alarm_name          = "ELB_UnHealthyHostCount_${element(var.load_balancers, count.index)}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "120"
  statistic           = "Average"
  threshold           = "${local.elb-thresholds["unhealthy_host_count"]}"
  alarm_description   = "Too Many UnHealthyHostCount"
  alarm_actions       = ["${aws_sns_topic.alerts.arn}"]
  dimensions = {
    LoadBalancer = "${element(var.load_balancers, count.index)}"
  }
}

resource "aws_cloudwatch_metric_alarm" "ELB_RejectedConnectionCount" {
  count               = "${length(var.load_balancers)}"
  alarm_name          = "ELB_RejectedConnectionCount_${element(var.load_balancers, count.index)}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "RejectedConnectionCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "${local.elb-thresholds["rejected_connection_count"]}"
  alarm_description   = "Too Many Rejected connections"
  alarm_actions       = ["${aws_sns_topic.alerts.arn}"]
  dimensions = {
    LoadBalancer = "${element(var.load_balancers, count.index)}"
  }
}
