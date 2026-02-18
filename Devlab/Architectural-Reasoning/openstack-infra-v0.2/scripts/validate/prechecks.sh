#!/bin/bash
# Pre-deployment Validation Script
# Runs various checks before deployment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INVENTORY_DIR="$PROJECT_ROOT/inventory/production"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

check_connectivity() {
    log_info "Checking SSH connectivity to all nodes..."
    ansible all -i "$INVENTORY_DIR/hosts.yml" -m ping || {
        log_error "SSH connectivity check failed"
        return 1
    }
    log_info "SSH connectivity OK"
}

check_disk_space() {
    log_info "Checking disk space on all nodes..."
    ansible all -i "$INVENTORY_DIR/hosts.yml" -m shell \
        -a "df -h / | awk 'NR==2 {print \$4}'" || {
        log_warn "Could not check disk space"
    }
}

check_python() {
    log_info "Checking Python availability on all nodes..."
    ansible all -i "$INVENTORY_DIR/hosts.yml" -m raw \
        -a "python3 --version" || {
        log_error "Python3 not available on all nodes"
        return 1
    }
    log_info "Python3 available on all nodes"
}

check_docker() {
    log_info "Checking Docker on all nodes..."
    ansible all -i "$INVENTORY_DIR/hosts.yml" -m shell \
        -a "docker --version" || {
        log_warn "Docker not found on some nodes (may be installed during deployment)"
    }
}

validate_inventory() {
    log_info "Validating inventory structure..."
    ansible-inventory -i "$INVENTORY_DIR/hosts.yml" --list > /dev/null || {
        log_error "Invalid inventory structure"
        return 1
    }
    log_info "Inventory structure valid"
}

validate_kolla_config() {
    log_info "Validating Kolla-Ansible configuration..."
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import yaml; yaml.safe_load(open('$PROJECT_ROOT/kolla/globals.yml'))" || {
            log_error "Invalid Kolla globals.yml"
            return 1
        }
    fi
    log_info "Kolla configuration valid"
}

# Run all checks
main() {
    log_info "Running pre-deployment validation checks..."
    
    validate_inventory
    validate_kolla_config
    check_connectivity
    check_python
    check_disk_space
    check_docker
    
    log_info "All validation checks completed"
}

main "$@"
