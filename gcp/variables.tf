variable "gcp_project_id" {
  description = "ID del proyecto en Google Cloud Platform (GCP)"
  type        = string
}

variable "gcp_region" {
  description = "Región de Google Cloud donde desplegar la infraestructura PoC"
  type        = string
  default     = "europe-west1" # Bélgica (o europe-west3 Fráncfort, us-central1 Iowa, etc.)
}

variable "gcp_zone" {
  description = "Zona de disponibilidad en GCP"
  type        = string
  default     = "europe-west1-b"
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

variable "machine_type" {
  description = "Tipo de máquina Compute Engine (e2-micro es económica para PoC)"
  type        = string
  default     = "e2-micro"
}

variable "subnet_cidr" {
  description = "Rango CIDR para la subred privada de GCP"
  type        = string
  default     = "10.10.1.0/24"
}

variable "allowed_source_ranges" {
  description = "Rangos IP autorizados para acceder a los nodos vía SSH y HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
