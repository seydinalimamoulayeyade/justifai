variable "name" {
  description = "Préfixe de nommage des ressources"
  type        = string
}

variable "account_id" {
  description = "ID du compte AWS (unicité du nom de bucket)"
  type        = string
}
