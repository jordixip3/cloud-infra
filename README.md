# ☁️ Cloud Infra — Multi-Cloud PoC Architecture (AWS • GCP • Azure)

Infraestructura como Código (**Terraform / OpenTofu**) modular y lista para producción para desplegar un entorno de pruebas (**PoC**) de **10 equipos/nodos interconectados** con topología de red aislada, cortafuegos perimetral, servidor web de verificación de estado y generación automática de claves de acceso SSH.

---

## 🏗️ Resumen de la Topología por Proveedor

| Componente | 🟧 Amazon Web Services (AWS) | 🟦 Google Cloud Platform (GCP) | 🟨 Microsoft Azure |
|---|---|---|---|
| **Directorio** | `aws/` | `gcp/` | `azure/` |
| **Red Aislada** | `aws_vpc` (10.0.0.0/16) | `google_compute_network` | `azurerm_virtual_network` (10.20.0.0/16) |
| **Subred** | `aws_subnet` (10.0.1.0/24) | `google_compute_subnetwork` (10.10.1.0/24) | `azurerm_subnet` (10.20.1.0/24) |
| **Pasarela / Salida** | `aws_internet_gateway` | Default Gateway GCP | Azure Default Outbound |
| **Cortafuegos** | `aws_security_group` (SSH, HTTP, ICMP) | `google_compute_firewall` (Tags) | `azurerm_network_security_group` (NSG) |
| **Equipos (10 Nodos)** | `aws_instance` (`t3.micro`) | `google_compute_instance` (`e2-micro`) | `azurerm_linux_virtual_machine` (`Standard_B1s`) |
| **Sistema Operativo** | Ubuntu 22.04 LTS Oficial | Debian 12 / Ubuntu 22.04 | Ubuntu Server 22.04 LTS |
| **Claves SSH** | Generadas automáticamente (`poc_key.pem`) | Generadas automáticamente (`gcp_poc_key.pem`) | Generadas automáticamente (`azure_poc_key.pem`) |
| **Servicio de Verificación** | Nginx con Banner HTML del Nodo e IPs | Nginx con Banner HTML del Nodo e IPs | Nginx con Banner HTML del Nodo e IPs |

---

## 🚀 Despliegue Rápido con `deploy.sh`

Se incluye un script orquestador en la raíz para facilitar la gestión sin recordar comandos complejos:

```bash
cd /Users/jordimaicas/Downloads/cloud-infra

# 1. Ver opciones y ayuda
./deploy.sh

# 2. Desplegar en AWS
./deploy.sh aws plan        # Previsualizar cambios
./deploy.sh aws apply       # Desplegar los 10 nodos

# 3. Desplegar en Google Cloud Platform (GCP)
./deploy.sh gcp plan
./deploy.sh gcp apply

# 4. Desplegar en Microsoft Azure
./deploy.sh azure plan
./deploy.sh azure apply

# 5. Obtener el inventario de IPs y comandos SSH
./deploy.sh aws output

# 6. Eliminar los recursos al finalizar la PoC
./deploy.sh aws destroy
```

---

## 🛠️ Despliegue Manual con Terraform CLI

### 1. Amazon Web Services (AWS)
Requisitos: Tener configuradas las credenciales de AWS CLI (`aws configure`).

```bash
cd /Users/jordimaicas/Downloads/cloud-infra/aws
terraform init
terraform plan
terraform apply -auto-approve
```
* Tras el despliegue, se creará el archivo `poc_key.pem` con permisos `0600`.
* Conexión por SSH a cualquiera de los nodos:
  ```bash
  ssh -i poc_key.pem ubuntu@<IP_PUBLICA>
  ```

---

### 2. Google Cloud Platform (GCP)
Requisitos: Tener configurado el SDK de Google Cloud (`gcloud auth application-default login`).

```bash
cd /Users/jordimaicas/Downloads/cloud-infra/gcp
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars y asignar tu gcp_project_id
terraform init
terraform plan
terraform apply -auto-approve
```
* Conexión por SSH:
  ```bash
  ssh -i gcp_poc_key.pem debian@<IP_EXTERNA>
  ```

---

### 3. Microsoft Azure
Requisitos: Tener iniciada sesión en Azure CLI (`az login`).

```bash
cd /Users/jordimaicas/Downloads/cloud-infra/azure
terraform init
terraform plan
terraform apply -auto-approve
```
* Conexión por SSH:
  ```bash
  ssh -i azure_poc_key.pem azureuser@<IP_PUBLICA>
  ```

---

## 💰 Optimización de Costes para la PoC
* **Tipos de instancia seleccionados:** `t3.micro` (AWS), `e2-micro` (GCP) y `Standard_B1s` (Azure).
* Todos ellos califican dentro de los tramos de capa gratuita o tienen un coste inferior a **0,01 $ / hora** por nodo, ideal para pruebas de concepto efímeras.
* Recuerda ejecutar `./deploy.sh <provider> destroy` cuando concluyas la prueba.
