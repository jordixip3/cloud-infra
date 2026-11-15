output "vpc_id" {
  description = "Identificador de la VPC creada"
  value       = aws_vpc.poc_vpc.id
}

output "subnet_id" {
  description = "Identificador de la subred pública"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "Identificador del Security Group de los nodos"
  value       = aws_security_group.nodes_sg.id
}

output "ssh_private_key_file" {
  description = "Ruta local de la clave privada SSH generada"
  value       = local_file.private_key_pem.filename
}

output "public_ips" {
  description = "Lista ordenada de las 10 IPs públicas asignadas a los equipos"
  value       = [for instance in aws_instance.poc_nodes : instance.public_ip]
}

output "private_ips" {
  description = "Lista ordenada de las 10 IPs privadas en la VPC"
  value       = [for instance in aws_instance.poc_nodes : instance.private_ip]
}

output "nodes_inventory" {
  description = "Inventario detallado de los 10 equipos con sus comandos de acceso directo"
  value = {
    for idx, instance in aws_instance.poc_nodes :
    format("poc-node-%02d", idx + 1) => {
      public_ip   = instance.public_ip
      private_ip  = instance.private_ip
      ssh_command = "ssh -i ${local_file.private_key_pem.filename} ubuntu@${instance.public_ip}"
      web_status  = "http://${instance.public_ip}"
    }
  }
}
