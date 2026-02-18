#!/bin/bash
# OpenStack Deployment Script
# This script deploys OpenStack using kolla-ansible
#
# Usage:
#   ./openstack-deploy.sh [prechecks|pull|deploy|postdeploy|all]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INVENTORY_DIR="$PROJECT_ROOT/inventory/production"
KOLLA_DIR="$PROJECT_ROOT/kolla"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v kolla-ansible >/dev/null 2>&1; then
        log_error "kolla-ansible not found. Please install kolla-ansible first."
        exit 1
    fi
    
    if ! command -v ansible-playbook >/dev/null 2>&1; then
        log_error "ansible-playbook not found. Please install Ansible first."
        exit 1
    fi
    
    if [ ! -f "$INVENTORY_DIR/hosts.yml" ]; then
        log_error "Inventory file not found: $INVENTORY_DIR/hosts.yml"
        exit 1
    fi
    
    if [ ! -f "$KOLLA_DIR/globals.yml" ]; then
        log_error "Kolla globals.yml not found: $KOLLA_DIR/globals.yml"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

run_prechecks() {
    log_info "Running OpenStack pre-deployment checks..."
    
    kolla-ansible -i "$INVENTORY_DIR/hosts.yml" prechecks || {
        log_error "Prechecks failed"
        exit 1
    }
    
    log_info "Prechecks completed successfully"
}

pull_images() {
    log_info "Pulling OpenStack container images..."
    
    kolla-ansible -i "$INVENTORY_DIR/hosts.yml" pull || {
        log_error "Failed to pull images"
        exit 1
    }
    
    log_info "Container images pulled successfully"
}

deploy_openstack() {
    log_info "Deploying OpenStack services..."
    
    kolla-ansible -i "$INVENTORY_DIR/hosts.yml" deploy || {
        log_error "Deployment failed"
        exit 1
    }
    
    log_info "OpenStack deployment completed successfully"
}

post_deploy() {
    log_info "Running post-deployment tasks..."
    
    kolla-ansible -i "$INVENTORY_DIR/hosts.yml" post-deploy || {
        log_error "Post-deployment tasks failed"
        exit 1
    }
    
    log_info "Post-deployment tasks completed"
    
    # Display admin credentials location
    log_info "Admin credentials available at: /etc/kolla/admin-openrc.sh"
    log_info "Source it with: source /etc/kolla/admin-openrc.sh"
}

verify_deployment() {
    log_info "Verifying deployment..."
    
    # Source admin credentials if available
    if [ -f "/etc/kolla/admin-openrc.sh" ]; then
        source /etc/kolla/admin-openrc.sh
        
        # Check services
        log_info "Checking OpenStack services..."
        openstack service list || {
            log_warn "Could not list services (may need to source admin-openrc.sh)"
        }
        
        # Check endpoints
        log_info "Checking endpoints..."
        openstack endpoint list || {
            log_warn "Could not list endpoints"
        }
        
        # Check compute nodes
        log_info "Checking compute nodes..."
        openstack hypervisor list || {
            log_warn "Could not list hypervisors"
        }
    else
        log_warn "Admin credentials not found, skipping verification"
    fi
    
    log_info "Verification completed"
}

deploy_all() {
    log_info "Starting full OpenStack deployment..."
    
    check_prerequisites
    run_prechecks
    pull_images
    deploy_openstack
    post_deploy
    verify_deployment
    
    log_info "Full deployment completed"
}

# Main
case "${1:-all}" in
    prechecks)
        check_prerequisites
        run_prechecks
        ;;
    pull)
        check_prerequisites
        pull_images
        ;;
    deploy)
        check_prerequisites
        deploy_openstack
        ;;
    postdeploy)
        check_prerequisites
        post_deploy
        ;;
    verify)
        verify_deployment
        ;;
    all)
        deploy_all
        ;;
    *)
        echo "Usage: $0 [prechecks|pull|deploy|postdeploy|verify|all]"
        echo ""
        echo "  prechecks   Run pre-deployment checks only"
        echo "  pull       Pull container images only"
        echo "  deploy     Deploy OpenStack services only"
        echo "  postdeploy Run post-deployment tasks only"
        echo "  verify     Verify deployment"
        echo "  all        Run full deployment (default)"
        exit 1
        ;;
esac
