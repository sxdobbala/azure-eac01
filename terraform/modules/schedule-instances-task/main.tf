locals {
  account_id = "${data.aws_caller_identity.current_identity.account_id}"
}

data "aws_caller_identity" "current_identity" {}

# Create a maintenance window
resource "aws_ssm_maintenance_window" "window" {
  name              = "${var.env_prefix}-${var.task_name}-maintenance-window"
  schedule          = "${var.maintenance_window_schedule_time}"
  schedule_timezone = "${var.maintenance_window_schedule_timezone}"
  duration          = "${var.maintenance_window_schedule_duration}"
  cutoff            = "${var.maintenance_window_schedule_cutoff}"
}

# Add target instances into maintenance window.
# If no instance found by tag, terraform apply runs successfully 
# and maintenance window task runs succesfully with 'NoInstancesInTag' as 'Status details' in console
resource "aws_ssm_maintenance_window_target" "targets" {
  window_id     = "${aws_ssm_maintenance_window.window.id}"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:optum:environment"
    values = ["${var.env_prefix}"]
  }
}

# Create maintenance window task for selected targets
resource "aws_ssm_maintenance_window_task" "task" {
  window_id        = "${aws_ssm_maintenance_window.window.id}"
  name             = "${var.env_prefix}-${var.task_name}-maintenance-window-task"
  description      = "${var.task_description}"
  task_type        = "RUN_COMMAND"
  task_arn         = "${var.task_arn}"
  priority         = 1
  service_role_arn = "arn:aws:iam::${local.account_id}:role/aws-service-role/ssm.amazonaws.com/AWSServiceRoleForAmazonSSM"
  max_concurrency  = "1"
  max_errors       = "1"

  targets {
    key    = "WindowTargetIds"
    values = ["${aws_ssm_maintenance_window_target.targets.id}"]
  }
}
