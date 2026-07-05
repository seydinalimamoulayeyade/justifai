output "alarms_topic_arn" {
  description = "ARN du topic SNS des alarmes"
  value       = aws_sns_topic.alarms.arn
}
