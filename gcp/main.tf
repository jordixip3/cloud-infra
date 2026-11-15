# ==============================================================================
# 1. RED VPC & SUBRED (GOOGLE CLOUD PLATFORM)
# ==============================================================================
resource "google_compute_network" "poc_vpc" {
  name                    = "${var.environment}-gcp-vpc"
  auto_create_subnetworks = false
  description             = "VPC personalizada para PoC multi-cloud de 10 equipos"
}

resource "google_compute_subnetwork" "poc_subnet" {
  name          = "${var.environment}-gcp-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.poc_vpc.id
}

# ==============================================================================
# 2. REGLAS DE CORTAFUEGOS (FIREWALL RULES)
# ==============================================================================
resource "google_compute_firewall" "allow_external" {
  name    = "${var.environment}-allow-external-ssh-http"
  network = google_compute_network.poc_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = var.allowed_source_ranges
  target_tags   = ["poc-node"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "${var.environment}-allow-internal-all"
  network = google_compute_network.poc_vpc.name

  allow {
    protocol = "all"
  }

  source_ranges = [var.subnet_cidr]
}

# ==============================================================================
# 3. CLAVE SSH GENERADA AUTOMÁTICAMENTE
# ==============================================================================
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/gcp_poc_key.pem"
  file_permission = "0600"
}

# ==============================================================================
# 4. DESPLIEGUE DE LOS 10 EQUIPOS (COMPUTE ENGINE INSTANCES)
# ==============================================================================
resource "google_compute_instance" "poc_nodes" {
  count        = var.node_count
  name         = format("poc-node-%02d", count.index + 1)
  machine_type = var.machine_type
  zone         = var.gcp_zone

  tags = ["poc-node", "worker"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 15 # GB
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.poc_subnet.id

    # Asigna IP pública efímera
    access_config {}
  }

  metadata = {
    ssh-keys = "debian:${tls_private_key.ssh_key.public_key_openssh}"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx curl jq htop

    NODE_NAME="poc-node-$(printf "%02d" ${count.index + 1})"
    hostnamectl set-hostname $NODE_NAME

    EXTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip || echo "pending")
    INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip || echo "pending")

    cat <<HTML > /var/www/html/index.html
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>$NODE_NAME - Cloud Infra PoC (GCP)</title>
      <style>
        body { font-family: -apple-system, system-ui, sans-serif; background: #0b132b; color: #f8fafc; padding: 40px; }
        .card { background: #1c2541; border-radius: 12px; padding: 24px; max-width: 600px; border: 1px solid #3a506b; }
        h1 { color: #48cae4; margin-top: 0; }
        .badge { background: #1d4ed8; color: #93c5fd; padding: 4px 10px; border-radius: 4px; font-weight: bold; }
        p { margin: 8px 0; color: #cbd5e1; }
        strong { color: #94a3b8; }
      </style>
    </head>
    <body>
      <div class="card">
        <span class="badge">GCP CLOUD INFRASTRUCTURE PoC</span>
        <h1>$NODE_NAME</h1>
        <p><strong>Cloud Provider:</strong> Google Cloud Platform (GCP)</p>
        <p><strong>Proyecto:</strong> ${var.gcp_project_id}</p>
        <p><strong>Zona:</strong> ${var.gcp_zone}</p>
        <p><strong>IP Externa:</strong> $EXTERNAL_IP</p>
        <p><strong>IP Interna:</strong> $INTERNAL_IP</p>
        <p><strong>Nodo ID:</strong> Nodo ${count.index + 1} de ${var.node_count}</p>
        <p><strong>Estado:</strong> ✅ Operativo & Conectado a Subred VPC</p>
      </div>
    </body>
    </html>
    HTML

    systemctl restart nginx
  EOF

  labels = {
    environment = var.environment
    project     = "cloud-infra-poc"
    managed_by  = "terraform"
  }
}
