variable "name" {
  description = "Préfixe de nommage des ressources"
  type        = string
}

variable "aws_region" {
  description = "Région AWS (construction de l'issuer JWT)"
  type        = string
}
