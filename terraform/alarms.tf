# ---------------------------------------------------------------------------
# Observabilité : alarmes CloudWatch (erreurs Lambda + profondeur DLQ)
# ---------------------------------------------------------------------------
resource "aws_sns_topic" "alarms" {
  name = "${local.name}-alarms"
}

resource "aws_sns_topic_subscription" "alarms_email" {
  count     = var.alarm_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# Erreurs sur chacune des Lambdas
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = {
    request_upload   = aws_lambda_function.request_upload.function_name
    process_document = aws_lambda_function.process_document.function_name
    notify           = aws_lambda_function.notify.function_name
  }

  alarm_name          = "${local.name}-${each.key}-errors"
  alarm_description   = "Erreurs sur la Lambda ${each.value}"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  period              = 300
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = each.value
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# Messages en attente dans la DLQ = échecs de notification à investiguer
resource "aws_cloudwatch_metric_alarm" "dlq_depth" {
  alarm_name          = "${local.name}-notify-dlq-depth"
  alarm_description   = "Messages présents dans la DLQ de notification"
  namespace           = "AWS/SQS"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  statistic           = "Maximum"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  period              = 300
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
}
