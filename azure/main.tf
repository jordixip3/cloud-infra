# ==============================================================================
# 1. GRUPO DE RECURSOS & RED VNET (MICROSOFT AZURE)
# ==============================================================================
resource "azurerm_resource_group" "poc_rg" {
  name     = "${var.environment}-azure-rg"
  location = var.azure_location

  tags = {
    Project     = "Cloud-Infra-PoC"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_virtual_network" "poc_vnet" {
  name                = "${var.environment}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.poc_rg.location
  resource_group_name = azurerm_resource_group.poc_rg.name
}

resource "azurerm_subnet" "poc_subnet" {
  name                 = "${var.environment}-subnet"
  resource_group_name  = azurerm_resource_group.poc_rg.name
  virtual_network_name = azurerm_virtual_network.poc_vnet.name
  address_prefixes     = [var.subnet_cidr]
}

# ==============================================================================
# 2. GRUPO DE SEGURIDAD DE RED (NETWORK SECURITY GROUP)
# ==============================================================================
resource "azurerm_network_security_group" "poc_nsg" {
  name                = "${var.environment}-nsg"
  location            = azurerm_resource_group.poc_rg.location
  resource_group_name = azurerm_resource_group.poc_rg.name

  # Regla 1: SSH (Puerto 22)
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_source
    destination_address_prefix = "*"
  }

  # Regla 2: HTTP (Puerto 80)
  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Regla 3: Intercomunicación interna completa entre los 10 nodos
  security_rule {
    name                       = "Allow-Internal-VNet"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.poc_subnet.id
  network_security_group_id = azurerm_network_security_group.poc_nsg.id
}

# ==============================================================================
# 3. CLAVE PRIVADA SSH AUTOGENERADA
# ==============================================================================
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/azure_poc_key.pem"
  file_permission = "0600"
}

# ==============================================================================
# 4. IPS PÚBLICAS E INTERFACES DE RED PARA CADA UNO DE LOS 10 NODOS
# ==============================================================================
resource "azurerm_public_ip" "poc_pip" {
  count               = var.node_count
  name                = format("poc-pip-%02d", count.index + 1)
  location            = azurerm_resource_group.poc_rg.location
  resource_group_name = azurerm_resource_group.poc_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "poc_nic" {
  count               = var.node_count
  name                = format("poc-nic-%02d", count.index + 1)
  location            = azurerm_resource_group.poc_rg.location
  resource_group_name = azurerm_resource_group.poc_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.poc_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.poc_pip[count.index].id
  }
}

# ==============================================================================
# 5. DESPLIEGUE DE LAS 10 MÁQUINAS VIRTUALES LINUX
# ==============================================================================
resource "azurerm_linux_virtual_machine" "poc_nodes" {
  count                           = var.node_count
  name                            = format("poc-node-%02d", count.index + 1)
  resource_group_name             = azurerm_resource_group.poc_rg.name
  location                        = azurerm_resource_group.poc_rg.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  network_interface_ids           = [azurerm_network_interface.poc_nic[count.index].id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx curl jq htop

    NODE_NAME="poc-node-$(printf "%02d" ${count.index + 1})"
    hostnamectl set-hostname $NODE_NAME

    cat <<HTML > /var/www/html/index.html
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>$NODE_NAME - Cloud Infra PoC (Azure)</title>
      <style>
        body { font-family: -apple-system, system-ui, sans-serif; background: #0c192c; color: #f8fafc; padding: 40px; }
        .card { background: #132d4b; border-radius: 12px; padding: 24px; max-width: 600px; border: 1px solid #1e4976; }
        h1 { color: #0078d4; margin-top: 0; }
        .badge { background: #004578; color: #70b0ff; padding: 4px 10px; border-radius: 4px; font-weight: bold; }
        p { margin: 8px 0; color: #cbd5e1; }
        strong { color: #94a3b8; }
      </style>
    </head>
    <body>
      <div class="card">
        <span class="badge">AZURE CLOUD INFRASTRUCTURE PoC</span>
        <h1>$NODE_NAME</h1>
        <p><strong>Cloud Provider:</strong> Microsoft Azure</p>
        <p><strong>Región:</strong> ${var.azure_location}</p>
        <p><strong>Nodo ID:</strong> Nodo ${count.index + 1} de ${var.node_count}</p>
        <p><strong>Estado:</strong> ✅ Operativo & Conectado a VNet Azure</p>
      </div>
    </body>
    </html>
    HTML

    systemctl restart nginx
  EOF
  )

  tags = {
    Name        = format("poc-node-%02d", count.index + 1)
    Environment = var.environment
    Role        = "Worker"
  }
}
