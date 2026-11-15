output "resource_group_name" {
  description = "Nombre del Resource Group en Azure"
  value       = azurerm_resource_group.poc_rg.name
}

output "vnet_name" {
  description = "Nombre de la Virtual Network"
  value       = azurerm_virtual_network.poc_vnet.name
}

output "ssh_private_key_file" {
  description = "Fichero de clave privada SSH para conectar a los equipos de Azure"
  value       = local_file.private_key_pem.filename
}

output "public_ips" {
  description = "Lista ordenada de las 10 IPs públicas de las VMs"
  value       = [for pip in azurerm_public_ip.poc_pip : pip.ip_address]
}

output "private_ips" {
  description = "Lista ordenada de las 10 IPs privadas en la subred"
  value       = [for nic in azurerm_network_interface.poc_nic : nic.private_ip_address]
}

output "nodes_inventory" {
  description = "Inventario detallado de los 10 nodos en Azure con comandos SSH directos"
  value = {
    for idx, vm in azurerm_linux_virtual_machine.poc_nodes :
    vm.name => {
      public_ip   = azurerm_public_ip.poc_pip[idx].ip_address
      private_ip  = azurerm_network_interface.poc_nic[idx].private_ip_address
      ssh_command = "ssh -i ${local_file.private_key_pem.filename} ${var.admin_username}@${azurerm_public_ip.poc_pip[idx].ip_address}"
      web_status  = "http://${azurerm_public_ip.poc_pip[idx].ip_address}"
    }
  }
}
