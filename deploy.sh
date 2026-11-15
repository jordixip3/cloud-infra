#!/usr/bin/env bash
# ==============================================================================
# CLOUD INFRA — MULTI-CLOUD TERRAFORM DEPLOYMENT CLI (AWS / GCP / AZURE)
# Despliegue automatizado de infraestructura PoC (10 equipos)
# ==============================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROVIDER="$1"
ACTION="${2:-plan}"

# Colors
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_BLUE="\033[34m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_RED="\033[31m"

show_help() {
  echo -e "${C_BOLD}CLOUD INFRA — GESTOR DE INFRAESTRUCTURA MULTI-CLOUD (10 EQUIPOS)${C_RESET}"
  echo -e "Uso: ./deploy.sh <aws|gcp|azure> [init|plan|apply|destroy|output]"
  echo ""
  echo "Ejemplos:"
  echo "  ./deploy.sh aws plan        # Previsualizar cambios en AWS"
  echo "  ./deploy.sh aws apply       # Desplegar los 10 equipos en AWS"
  echo "  ./deploy.sh gcp apply       # Desplegar los 10 equipos en GCP"
  echo "  ./deploy.sh azure apply     # Desplegar los 10 equipos en Azure"
  echo "  ./deploy.sh aws destroy     # Eliminar todos los recursos en AWS"
  echo "  ./deploy.sh aws output      # Ver IPs y comandos SSH generados"
  exit 1
}

if [[ -z "$PROVIDER" || ( "$PROVIDER" != "aws" && "$PROVIDER" != "gcp" && "$PROVIDER" != "azure" ) ]]; then
  show_help
fi

# 1. Comprobar binario de Terraform
if ! command -v terraform &> /dev/null; then
  echo -e "${C_RED}❌ Error: 'terraform' no está instalado en este sistema.${C_RESET}"
  echo -e "${C_YELLOW}💡 Puedes instalarlo en macOS rápidamente mediante Homebrew:${C_RESET}"
  echo -e "   brew tap hashicorp/tap"
  echo -e "   brew install hashicorp/tap/terraform"
  echo -e "   # O usar OpenTofu: brew install opentofu"
  exit 1
fi

TARGET_DIR="$DIR/$PROVIDER"
cd "$TARGET_DIR"

echo -e "${C_BLUE}================================================================${C_RESET}"
echo -e "${C_BOLD}🚀 CLOUD INFRA PoC: ${PROVIDER^^} | ACCIÓN: ${ACTION^^}${C_RESET}"
echo -e "${C_BLUE}Directorio de trabajo: $TARGET_DIR${C_RESET}"
echo -e "${C_BLUE}================================================================${C_RESET}"

# 2. Comprobar credenciales del proveedor correspondiente
case "$PROVIDER" in
  aws)
    echo -e "${C_YELLOW}🔍 Verificando credenciales AWS CLI...${C_RESET}"
    if command -v aws &> /dev/null; then
      aws sts get-caller-identity --output json 2>/dev/null || {
        echo -e "${C_RED}⚠️ Advertencia: No se detectó sesión activa de AWS CLI.${C_RESET}"
        echo -e "   Ejecuta 'aws configure' o exporta AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY."
      }
    fi
    ;;
  gcp)
    echo -e "${C_YELLOW}🔍 Verificando configuración GCP...${C_RESET}"
    if [ ! -f "terraform.tfvars" ]; then
      if [ -f "terraform.tfvars.example" ]; then
        echo -e "${C_YELLOW}⚠️ Creando terraform.tfvars desde plantilla. Recuerda configurar tu gcp_project_id.${C_RESET}"
        cp terraform.tfvars.example terraform.tfvars
      fi
    fi
    ;;
  azure)
    echo -e "${C_YELLOW}🔍 Verificando sesión Azure CLI...${C_RESET}"
    if command -v az &> /dev/null; then
      az account show --output json 2>/dev/null || {
        echo -e "${C_RED}⚠️ Advertencia: No se detectó sesión activa de Azure CLI.${C_RESET}"
        echo -e "   Ejecuta 'az login' para autenticarte."
      }
    fi
    ;;
esac

# 3. Inicialización automática si no existe .terraform
if [ ! -d ".terraform" ] || [ "$ACTION" == "init" ]; then
  echo -e "\n${C_GREEN}📦 Inicializando Terraform y descargando providers...${C_RESET}"
  terraform init
  if [ "$ACTION" == "init" ]; then
    echo -e "${C_GREEN}✅ Inicialización completada.${C_RESET}"
    exit 0
  fi
fi

# 4. Ejecutar acción solicitada
case "$ACTION" in
  plan)
    echo -e "\n${C_GREEN}📋 Ejecutando terraform plan...${C_RESET}"
    terraform plan
    ;;
  apply)
    echo -e "\n${C_GREEN}🚀 Desplegando los 10 equipos en ${PROVIDER^^}...${C_RESET}"
    terraform apply -auto-approve
    echo -e "\n${C_GREEN}================================================================${C_RESET}"
    echo -e "${C_BOLD}✅ INFRAESTRUCTURA DE 10 EQUIPOS DESPLEGADA EXITOSAMENTE EN ${PROVIDER^^}${C_RESET}"
    echo -e "${C_GREEN}================================================================${C_RESET}"
    terraform output
    ;;
  destroy)
    echo -e "\n${C_RED}⚠️ Destruyendo recursos de la PoC en ${PROVIDER^^}...${C_RESET}"
    terraform destroy
    ;;
  output)
    terraform output
    ;;
  *)
    show_help
    ;;
esac
