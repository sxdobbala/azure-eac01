locals {
  rule_name = "${var.rule_name == "" ? "schedule-run-${var.env_prefix}-${var.lambda_name}" : var.rule_name}"
}

resource "aws_cloudwatch_event_rule" "cloudwatch-event-rule" {
  name                = "${local.rule_name}"
  description         = "Runs ${var.lambda_name} lambda on a schedule"
  schedule_expression = "${var.schedule_expression}"
}

resource "aws_cloudwatch_event_target" "cloudwatch-event-target" {
  rule      = "${aws_cloudwatch_event_rule.cloudwatch-event-rule.name}"
  target_id = "${var.lambda_name}"
  arn       = "${var.lambda_arn}"
}

resource "aws_lambda_permission" "cloudwatch-permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${var.lambda_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.cloudwatch-event-rule.arn}"
}
