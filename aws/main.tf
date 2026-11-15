# ==============================================================================
# 1. RED & TOPOLOGÍA VPC (AWS)
# ==============================================================================
resource "aws_vpc" "poc_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.poc_vpc.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.poc_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "${var.environment}-public-subnet"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.poc_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# ==============================================================================
# 2. SEGURIDAD & CORTAFUEGOS (SECURITY GROUP)
# ==============================================================================
resource "aws_security_group" "nodes_sg" {
  name        = "${var.environment}-nodes-sg"
  description = "Reglas perimetrales PoC: SSH, HTTP e interconexion interna de los 10 nodos"
  vpc_id      = aws_vpc.poc_vpc.id

  # Acceso SSH de administración
  ingress {
    description = "SSH de gestion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Acceso Web HTTP para verificación de estado del nodo
  ingress {
    description = "HTTP Web Banner"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tráfico ICMP (Ping) para pruebas de conectividad
  ingress {
    description = "ICMP Ping"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr, var.allowed_ssh_cidr]
  }

  # Comunicación interna completa entre los 10 equipos dentro de la VPC
  ingress {
    description = "Intercomunicacion interna entre nodos PoC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # Salida libre a Internet (actualizaciones, repositorios, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-nodes-sg"
  }
}

# ==============================================================================
# 3. GESTIÓN DE CLAVES SSH (AUTOGENERADA PARA FACILIDAD EN POC)
# ==============================================================================
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${var.environment}-poc-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/poc_key.pem"
  file_permission = "0600"
}

# ==============================================================================
# 4. AMI OFICIAL DE UBUNTU 22.04 LTS
# ==============================================================================
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*", "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ==============================================================================
# 5. DESPLIEGUE DE LOS 10 EQUIPOS (INSTANCIAS EC2)
# ==============================================================================
resource "aws_instance" "poc_nodes" {
  count                  = var.node_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.nodes_sg.id]
  key_name               = aws_key_pair.generated_key.key_name

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 15 # GB
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  # Script de inicio para levantar un servicio web con información del nodo
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx curl jq htop

              NODE_NAME="poc-node-$(printf "%02d" ${count.index + 1})"
              hostnamectl set-hostname $NODE_NAME

              PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "pending")
              PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 || echo "pending")

              cat <<HTML > /var/www/html/index.html
              <!DOCTYPE html>
              <html>
              <head>
                <meta charset="utf-8">
                <title>$NODE_NAME - Cloud Infra PoC (AWS)</title>
                <style>
                  body { font-family: -apple-system, system-ui, sans-serif; background: #0f172a; color: #f8fafc; padding: 40px; }
                  .card { background: #1e293b; border-radius: 12px; padding: 24px; max-width: 600px; border: 1px solid #334155; }
                  h1 { color: #38bdf8; margin-top: 0; }
                  .badge { background: #047857; color: #34d399; padding: 4px 10px; border-radius: 4px; font-weight: bold; }
                  p { margin: 8px 0; color: #cbd5e1; }
                  strong { color: #94a3b8; }
                </style>
              </head>
              <body>
                <div class="card">
                  <span class="badge">AWS CLOUD INFRASTRUCTURE PoC</span>
                  <h1>$NODE_NAME</h1>
                  <p><strong>Cloud Provider:</strong> Amazon Web Services (AWS)</p>
                  <p><strong>Región:</strong> ${var.aws_region}</p>
                  <p><strong>IP Pública:</strong> $PUBLIC_IP</p>
                  <p><strong>IP Privada:</strong> $PRIVATE_IP</p>
                  <p><strong>Nodo ID:</strong> Nodo ${count.index + 1} de ${var.node_count}</p>
                  <p><strong>Estado:</strong> ✅ Operativo & Conectado a la VPC</p>
                </div>
              </body>
              </html>
              HTML

              systemctl restart nginx
              EOF

  tags = {
    Name = format("poc-node-%02d", count.index + 1)
    Role = "PoC-Worker"
  }
}
