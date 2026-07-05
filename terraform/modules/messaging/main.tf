# Messagerie : SNS (email) + SQS (+ DLQ) pour découpler la notification
resource "aws_sns_topic" "notifications" {
  name = "${var.name}-notifications"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_sqs_queue" "dlq" {
  name = "${var.name}-notify-dlq"
}

resource "aws_sqs_queue" "notify" {
  name = "${var.name}-notify"
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}
