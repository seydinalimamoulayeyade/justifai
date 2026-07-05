variable "name" {
  description = "Préfixe de nommage des ressources"
  type        = string
}

variable "notification_email" {
  description = "Email abonné au topic SNS de notification"
  type        = string
}
