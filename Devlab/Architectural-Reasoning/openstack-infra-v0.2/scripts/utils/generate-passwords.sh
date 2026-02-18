#!/bin/bash
# Password Generation Script
# Generates secure random passwords for OpenStack services
#
# Usage:
#   ./generate-passwords.sh [length]
#   Default length: 32

set -euo pipefail

LENGTH="${1:-32}"

generate_password() {
    openssl rand -base64 "$LENGTH" | tr -d "=+/" | cut -c1-"$LENGTH"
}

echo "# Generated passwords (replace in kolla/passwords.yml)"
echo ""
echo "database_password: \"$(generate_password)\""
echo "rabbitmq_password: \"$(generate_password)\""
echo "keystone_admin_password: \"$(generate_password)\""
echo "horizon_secret_key: \"$(generate_password)\""
echo "grafana_admin_password: \"$(generate_password)\""
echo "prometheus_admin_password: \"$(generate_password)\""
