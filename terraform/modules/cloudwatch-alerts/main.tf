#resource aws_sns
resource "aws_sns_topic" "alerts" {
  name = "${var.env_prefix}-threshold-alerts"

  delivery_policy = <<EOF
  {
    "http": {
      "defaultHealthyRetryPolicy": {
        "minDelayTarget": 20,
        "maxDelayTarget": 20,
        "numRetries": 3,
        "numMaxDelayRetries": 0,
        "numNoDelayRetries": 0,
        "numMinDelayRetries": 0,
        "backoffFunction": "linear"
      },
      "disableSubscriptionOverrides": false,
      "defaultThrottlePolicy": {
        "maxReceivesPerSecond": 1
      }
    }
  }
  EOF

  #Use the below method for email notification. Temperoary until the lambda is not done.
  provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${var.alarms_email}"
  }
}

#TODO: Uncomment the below module and resource to finihs the lambda-flowdock integration
# module "flowdock-alert-integration" {
#   source        = "git::https://github.optum.com/CommercialCloud-EAC/aws_lambda.git?ref=v2.0.0"
#   function_name = "${var.env_prefix}-flowdock-alert-integration"
#   description   = "Lambda function to post messages on flowdock"
#   s3_bucket     = "${var.opa_api_source_code_s3_bucket}"
#   s3_key        = "${var.opa_api_source_code_s3_key}"
#   handler       = "opa.exec.flowdock_sns.lambda_handler"


#   triggers = [{
#     trigger_id         = "AllowExecuteFromSNS"
#     trigger_principal  = "sns.amazonaws.com"
#     trigger_source_arn = "${aws_sns_topic.alerts.arn}"
#   }]
# }


# resource "aws_sns_topic_subscription" "flowdock_sns" {
#   topic_arn = "${aws_sns_topic.alerts.arn}"
#   protocol  = "lambda"
#   endpoint  = "${module.flowdock-alert-integration.arn}"
# }

