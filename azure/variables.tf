variable "azure_location" {
  description = "Región de Azure donde desplegar la infraestructura PoC"
  type        = string
  default     = "westeurope" # Países Bajos (o uksouth, eastus, etc.)
}

variable "environment" {
  description = "Nombre del entorno"
  type        = string
  default     = "poc"
}

variable "node_count" {
  description = "Número de máquinas virtuales a desplegar (PoC: 10 equipos)"
  type        = number
  default     = 10
}

variable "vm_size" {
  description = "Tamaño de máquina virtual Azure (Standard_B1s es económica para PoC)"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Usuario administrador del sistema Linux"
  type        = string
  default     = "azureuser"
}

variable "vnet_cidr" {
  description = "Rango de direcciones de la Virtual Network"
  type        = string
  default     = "10.20.0.0/16"
}

variable "subnet_cidr" {
  description = "Rango de direcciones de la Subred"
  type        = string
  default     = "10.20.1.0/24"
}

variable "allowed_ssh_source" {
  description = "CIDR autorizado para acceso SSH y administración"
  type        = string
  default     = "*"
}
