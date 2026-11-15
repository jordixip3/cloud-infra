output "network_name" {
  description = "Nombre de la red VPC en Google Cloud"
  value       = google_compute_network.poc_vpc.name
}

output "subnetwork_name" {
  description = "Nombre de la subred creada"
  value       = google_compute_subnetwork.poc_subnet.name
}

output "ssh_private_key_file" {
  description = "Fichero de clave privada SSH para conectar a los equipos GCP"
  value       = local_file.private_key_pem.filename
}

output "public_ips" {
  description = "Lista ordenada de las 10 IPs públicas externas asignadas"
  value = [
    for instance in google_compute_instance.poc_nodes :
    instance.network_interface[0].access_config[0].nat_ip
  ]
}

output "internal_ips" {
  description = "Lista de IPs privadas internas en la subred de GCP"
  value = [
    for instance in google_compute_instance.poc_nodes :
    instance.network_interface[0].network_ip
  ]
}

output "nodes_inventory" {
  description = "Inventario detallado de los 10 nodos en GCP con comandos de acceso SSH"
  value = {
    for idx, instance in google_compute_instance.poc_nodes :
    instance.name => {
      external_ip = instance.network_interface[0].access_config[0].nat_ip
      internal_ip = instance.network_interface[0].network_ip
      zone        = instance.zone
      ssh_command = "ssh -i ${local_file.private_key_pem.filename} debian@${instance.network_interface[0].access_config[0].nat_ip}"
      web_status  = "http://${instance.network_interface[0].access_config[0].nat_ip}"
    }
  }
}
