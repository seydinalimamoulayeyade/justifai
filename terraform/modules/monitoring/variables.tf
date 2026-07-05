variable "name" {
  description = "Préfixe de nommage des ressources"
  type        = string
}

variable "alarm_email" {
  description = "Email destinataire des alarmes (vide = pas d'abonnement)"
  type        = string
  default     = ""
}

variable "function_names" {
  description = "Noms des Lambdas à surveiller, indexés par clé logique"
  type        = map(string)
}

variable "dlq_name" {
  description = "Nom de la DLQ à surveiller"
  type        = string
}
