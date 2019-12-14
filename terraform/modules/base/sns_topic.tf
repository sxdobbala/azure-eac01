resource "aws_sns_topic" "ci-sns-topic" {
  name = "${var.env_prefix}-ci-sns-topic"

  provisioner "local-exec" {
    # Hack to subscribe email to SNS topic.
    # Email subscription is not supported because the endpoint needs to be authorized and does not generate an ARN until the target email address has been validated.
    # Subscription policy can be updated later (e.g. get only messages with ExecutionStatus as "failed").
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${var.ci_email}"
  }
}

resource "aws_sns_topic" "opa-operations-sns-topic" {
  name = "${var.env_prefix}-opa-operations-sns-topic"

  provisioner "local-exec" {
    # Hack to subscribe email to SNS topic.
    # Email subscription is not supported because the endpoint needs to be authorized and does not generate an ARN until the target email address has been validated.
    # Subscription policy can be updated later (e.g. get only messages with ExecutionStatus as "failed").
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${var.opa_operations_email}"
  }
}
