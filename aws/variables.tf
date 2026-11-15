variable "aws_region" {
  description = "Región de AWS donde desplegar la infraestructura PoC"
  type        = string
  default     = "eu-west-1" # Irlanda (o cambiar a us-east-1, eu-central-1, etc.)
}

variable "environment" {
  description = "Nombre del entorno"
  type        = string
  default     = "poc"
}

variable "node_count" {
  description = "Número de equipos/instancias a aprovisionar (PoC: 10 equipos)"
  type        = number
  default     = 10
}

variable "instance_type" {
  description = "Tipo de instancia EC2 (t3.micro es ligera y económica para PoC)"
  type        = string
  default     = "t3.micro"
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Bloque CIDR de la subred pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR autorizado para acceso SSH y administración (por defecto abierto 0.0.0.0/0 para PoC)"
  type        = string
  default     = "0.0.0.0/0"
}
