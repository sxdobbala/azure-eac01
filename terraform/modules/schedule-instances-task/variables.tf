variable "task_name" {
  description = "The name of maintenance window task"
}

variable "task_description" {
  description = "The description of maintenance window task"
}

variable "task_arn" {
  description = "The ARN of task. Eg, AWS-UpdateSSMAgent or AWS-RunShellScript"
}

variable "maintenance_window_schedule_time" {
  description = "Follow cron rules. Eg, cron(30 16 * * ? *) : every day at 16:30"
}

# INeed to use ANA timezone, https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
variable "maintenance_window_schedule_timezone" {
  default = "America/New_York"
}

variable "maintenance_window_schedule_duration" {
  description = "Maintenance window running hours"
}

variable "maintenance_window_schedule_cutoff" {
  description = "The number of hours before the end of the maintenance window that Systems Manager stops scheduling new tasks for execution"
}

variable "env_prefix" {
  description = "Environment specific prefix to uniquely identify resources for an environment. e.g. dev/qa/state/prod or dev-joe"
}
