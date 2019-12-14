locals {
  # timeout for the queues needs to be equal or greater to the timeout for the lambda
  timeout_seconds = 300

  # S3 location where registry data will be saved and can be retrieved by LINK team
  s3_registry_data_location = "arn:aws:s3:::${var.s3_bucket}/${var.s3_prefix}/*"

  function_name = "${var.env_prefix}-link-registry-handler"
}

resource "aws_sns_topic" "registry-change-sns-topic" {
  name = "${var.env_prefix}-registry-change-sns-topic"
}

resource "aws_sns_topic_policy" "registry-change-sns-topic-policy" {
  arn    = "${aws_sns_topic.registry-change-sns-topic.arn}"
  policy = "${data.aws_iam_policy_document.registry-change-sns-topic-policy-doc.json}"
}

data "aws_iam_policy_document" "registry-change-sns-topic-policy-doc" {
  statement {
    sid    = "AllowLinkSubscribe"
    effect = "Allow"

    actions = [
      "SNS:Subscribe",
      "SNS:Receive",
    ]

    principals {
      type        = "AWS"
      identifiers = ["${var.link_service_role_arn}"]
    }

    resources = ["${aws_sns_topic.registry-change-sns-topic.arn}"]
  }

  statement {
    sid    = "AllowMSTRPublish"
    effect = "Allow"

    actions = [
      "SNS:Publish",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.aws_account_id}:role/MSTRInstanceProfileRole-${local.aws_region}"]
    }

    resources = ["${aws_sns_topic.registry-change-sns-topic.arn}"]
  }
}

resource "aws_sqs_queue" "registry-dead-letter-queue" {
  name                      = "${var.env_prefix}-registry-dead-letter-queue"
  message_retention_seconds = 345600
  tags                      = "${var.global_tags}"
}

resource "aws_sqs_queue" "registry-request-queue" {
  name                       = "${var.env_prefix}-registry-request-queue"
  visibility_timeout_seconds = "${local.timeout_seconds}"
  redrive_policy             = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.registry-dead-letter-queue.arn}\",\"maxReceiveCount\":5}"
  tags                       = "${var.global_tags}"
}

resource "aws_sqs_queue_policy" "registry-request-queue-policy" {
  queue_url = "${aws_sqs_queue.registry-request-queue.id}"
  policy    = "${data.aws_iam_policy_document.registry-request-queue-policy-doc.json}"
}

data "aws_iam_policy_document" "registry-request-queue-policy-doc" {
  statement {
    effect = "Allow"

    actions = [
      "SQS:GetQueueUrl",
      "SQS:GetQueueAttributes",
      "SQS:SendMessage",
    ]

    principals {
      type        = "AWS"
      identifiers = ["${var.link_service_role_arn}"]
    }

    resources = ["${aws_sqs_queue.registry-request-queue.arn}"]
  }
}

resource "aws_sqs_queue" "registry-response-queue" {
  name                       = "${var.env_prefix}-registry-response-queue"
  visibility_timeout_seconds = "${local.timeout_seconds}"
  redrive_policy             = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.registry-dead-letter-queue.arn}\",\"maxReceiveCount\":5}"
  tags                       = "${var.global_tags}"
}

resource "aws_sqs_queue_policy" "registry-response-queue-policy" {
  queue_url = "${aws_sqs_queue.registry-response-queue.id}"
  policy    = "${data.aws_iam_policy_document.registry-response-queue-policy-doc.json}"
}

data "aws_iam_policy_document" "registry-response-queue-policy-doc" {
  statement {
    effect = "Allow"

    actions = [
      "SQS:GetQueueUrl",
      "SQS:GetQueueAttributes",
      "SQS:ReceiveMessage",
      "SQS:DeleteMessage",
    ]

    principals {
      type        = "AWS"
      identifiers = ["${var.link_service_role_arn}"]
    }

    resources = ["${aws_sqs_queue.registry-response-queue.arn}"]
  }
}

resource "aws_sqs_queue" "registry-notification-queue" {
  name                       = "${var.env_prefix}-registry-notification-queue"
  visibility_timeout_seconds = "${local.timeout_seconds}"
  redrive_policy             = "{\"deadLetterTargetArn\":\"${aws_sqs_queue.registry-dead-letter-queue.arn}\",\"maxReceiveCount\":5}"
  tags                       = "${var.global_tags}"
}

resource "aws_sqs_queue_policy" "registry-notification-queue-policy" {
  queue_url = "${aws_sqs_queue.registry-notification-queue.id}"
  policy    = "${data.aws_iam_policy_document.registry-notification-queue-policy-doc.json}"
}

data "aws_iam_policy_document" "registry-notification-queue-policy-doc" {
  statement {
    effect = "Allow"

    actions = [
      "SQS:GetQueueUrl",
      "SQS:GetQueueAttributes",
      "SQS:ReceiveMessage",
      "SQS:DeleteMessage",
    ]

    principals {
      type        = "AWS"
      identifiers = ["${var.link_service_role_arn}"]
    }

    resources = ["${aws_sqs_queue.registry-notification-queue.arn}"]
  }

  # allow SNS topic to send messages to SQS queue subscription
  # see: https://docs.aws.amazon.com/sns/latest/dg/sns-sqs-as-subscriber.html#SendMessageToSQS.sqs.permissions
  statement {
    effect  = "Allow"
    actions = ["SQS:SendMessage"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = ["${aws_sns_topic.registry-change-sns-topic.arn}"]
    }

    resources = ["${aws_sqs_queue.registry-notification-queue.arn}"]
  }
}

resource "aws_sns_topic_subscription" "registry-notification-queue-subscription" {
  topic_arn            = "${aws_sns_topic.registry-change-sns-topic.arn}"
  protocol             = "sqs"
  endpoint             = "${aws_sqs_queue.registry-notification-queue.arn}"
  raw_message_delivery = true
}

# Create a SNS topic for lambda so we can send lambda failures for debugging
resource "aws_sns_topic" "link_dlq_sns" {
  name = "${var.env_prefix}-link-dlq"
}

module "link-registry-handler" {
  source = "git::https://github.optum.com/oaccoe/aws_lambda.git"

  description      = "OPA Lambda to handle registry requests from LINK"
  function_name    = "${local.function_name}"
  s3_bucket        = "${var.opa_api_source_code_s3_bucket}"
  s3_key           = "${var.opa_api_source_code_s3_key}"
  is_local_archive = "false"
  handler          = "opa.exec.link_registry_handler.lambda_handler"
  timeout          = "${local.timeout_seconds}"
  trigger_count    = 0

  subnet_ids         = ["${var.private_subnet_ids}"]
  security_group_ids = ["${aws_security_group.link-registry-handler-sg.id}", "${var.dataloader_egress_sg_id}"]

  environment_vars = {
    S3_BUCKET          = "${var.s3_bucket}"
    S3_PREFIX          = "${var.s3_prefix}"
    REGISTRY_API_URL   = "${var.registry_api_url}"
    RESPONSE_QUEUE_URL = "${aws_sqs_queue.registry-response-queue.id}"
  }

  custom_inline_policy_count = 1

  custom_inline_policies = [
    {
      custom_inline_name   = "LinkRegistryAccess"
      custom_inline_policy = "${data.aws_iam_policy_document.link-registry-handler-policy.json}"
    },
  ]

  custom_managed_policies = ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]

  # lambda execution failures will be sent to this SNS topic
  dead_letter_config = {
    target_arn = "${aws_sns_topic.link_dlq_sns.arn}"
  }

  global_tags = "${var.global_tags}"
}

data "aws_iam_policy_document" "link-registry-handler-policy" {
  statement {
    effect    = "Allow"
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    resources = ["${aws_sqs_queue.registry-request-queue.arn}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["sqs:SendMessage", "sqs:GetQueueAttributes"]
    resources = ["${aws_sqs_queue.registry-response-queue.arn}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${local.s3_registry_data_location}"]
  }
}

resource "aws_lambda_event_source_mapping" "link-registry-handler-source-mapping" {
  event_source_arn = "${aws_sqs_queue.registry-request-queue.arn}"
  function_name    = "${module.link-registry-handler.arn}"

  # pass a single record to the lambda
  batch_size = 1
}

resource "aws_security_group" "link-registry-handler-sg" {
  name        = "${local.function_name}-sg"
  description = "Security group for ${local.function_name} lambda"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr_block}", "${var.hybrid_cidr_block}"]
  }

  tags = "${var.global_tags}"
}
