output "topic_arn" {
  description = "ARN du topic SNS de notification"
  value       = aws_sns_topic.notifications.arn
}

output "queue_arn" {
  description = "ARN de la file SQS de notification"
  value       = aws_sqs_queue.notify.arn
}

output "queue_url" {
  description = "URL de la file SQS de notification"
  value       = aws_sqs_queue.notify.url
}

output "dlq_name" {
  description = "Nom de la DLQ"
  value       = aws_sqs_queue.dlq.name
}

output "dlq_arn" {
  description = "ARN de la DLQ"
  value       = aws_sqs_queue.dlq.arn
}
