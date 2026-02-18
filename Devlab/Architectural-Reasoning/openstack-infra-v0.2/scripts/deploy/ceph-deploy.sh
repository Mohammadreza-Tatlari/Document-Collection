#!/bin/bash
# Ceph Deployment Script
# This script deploys Ceph cluster using cephadm
#
# Usage:
#   ./ceph-deploy.sh --dry-run    # Validate configuration
#   ./ceph-deploy.sh --apply      # Deploy Ceph cluster

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INVENTORY_DIR="$PROJECT_ROOT/inventory/production"
CEPH_DIR="$PROJECT_ROOT/ceph"

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
    
    if ! command -v cephadm >/dev/null 2>&1; then
        log_error "cephadm not found. Please install cephadm first."
        exit 1
    fi
    
    if ! command -v ansible-playbook >/dev/null 2>&1; then
        log_error "ansible-playbook not found. Please install Ansible first."
        exit 1
    fi
    
    if [ ! -f "$CEPH_DIR/cluster-spec.yaml" ]; then
        log_error "Ceph cluster spec not found: $CEPH_DIR/cluster-spec.yaml"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

validate_config() {
    log_info "Validating Ceph configuration..."
    
    # Validate YAML syntax
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import yaml; yaml.safe_load(open('$CEPH_DIR/cluster-spec.yaml'))" || {
            log_error "Invalid YAML syntax in cluster-spec.yaml"
            exit 1
        }
    fi
    
    # Validate pools.yaml if exists
    if [ -f "$CEPH_DIR/pools.yaml" ]; then
        python3 -c "import yaml; yaml.safe_load(open('$CEPH_DIR/pools.yaml'))" || {
            log_error "Invalid YAML syntax in pools.yaml"
            exit 1
        }
    fi
    
    log_info "Configuration validation passed"
}

dry_run() {
    log_info "Running dry-run validation..."
    
    check_prerequisites
    validate_config
    
    log_info "Dry-run completed successfully"
    log_info "Configuration files are valid"
    log_info "Ready for deployment"
}

bootstrap_cluster() {
    log_info "Bootstrapping Ceph cluster..."
    
    # Check if cluster already exists
    if cephadm shell -- ceph -s >/dev/null 2>&1; then
        log_warn "Ceph cluster already exists, skipping bootstrap"
        return 0
    fi
    
    # Get bootstrap node IP from inventory
    BOOTSTRAP_NODE=$(ansible-inventory -i "$INVENTORY_DIR/hosts.yml" --list | \
        python3 -c "import sys, json; data=json.load(sys.stdin); \
        print(data['all']['children']['ceph-mon']['hosts'][list(data['all']['children']['ceph-mon']['hosts'].keys())[0]]['ansible_host'])")
    
    if [ -z "$BOOTSTRAP_NODE" ]; then
        log_error "Could not determine bootstrap node IP"
        exit 1
    fi
    
    log_info "Bootstrap node: $BOOTSTRAP_NODE"
    
    # Bootstrap cluster
    cephadm bootstrap --mon-ip "$BOOTSTRAP_NODE" \
        --allow-fqdn-hostname || {
        log_error "Ceph bootstrap failed"
        exit 1
    }
    
    log_info "Ceph cluster bootstrapped successfully"
}

add_hosts() {
    log_info "Adding hosts to Ceph cluster..."
    
    # Get all hosts from inventory
    HOSTS=$(ansible-inventory -i "$INVENTORY_DIR/hosts.yml" --list | \
        python3 -c "import sys, json; \
        data=json.load(sys.stdin); \
        hosts = []; \
        for group in ['ceph-mon', 'ceph-osd']: \
            if group in data['all']['children']: \
                for host, vars in data['all']['children'][group]['hosts'].items(): \
                    hosts.append((host, vars.get('ansible_host', host))); \
        print('\\n'.join([f'{h[0]}:{h[1]}' for h in set(hosts)]))")
    
    while IFS=: read -r hostname ip; do
        log_info "Adding host: $hostname ($ip)"
        cephadm shell -- ceph orch host add "$hostname" "$ip" || {
            log_warn "Failed to add host $hostname (may already exist)"
        }
    done <<< "$HOSTS"
    
    log_info "Hosts added to cluster"
}

apply_cluster_spec() {
    log_info "Applying cluster specification..."
    
    cephadm shell -- ceph orch apply -i "$CEPH_DIR/cluster-spec.yaml" || {
        log_error "Failed to apply cluster spec"
        exit 1
    }
    
    log_info "Cluster specification applied"
}

create_osds() {
    log_info "Creating OSDs..."
    
    if [ ! -d "$CEPH_DIR/osd-specs" ]; then
        log_warn "OSD specs directory not found, skipping OSD creation"
        log_warn "Create OSD specs in $CEPH_DIR/osd-specs/ and run manually"
        return 0
    fi
    
    for osd_spec in "$CEPH_DIR/osd-specs"/*-osds.yaml; do
        if [ -f "$osd_spec" ]; then
            log_info "Applying OSD spec: $(basename "$osd_spec")"
            cephadm shell -- ceph orch apply osd -i "$osd_spec" || {
                log_warn "Failed to apply OSD spec: $osd_spec"
            }
        fi
    done
    
    log_info "OSD creation initiated"
}

create_pools() {
    log_info "Creating Ceph pools..."
    
    if [ ! -f "$CEPH_DIR/pools.yaml" ]; then
        log_warn "pools.yaml not found, skipping pool creation"
        return 0
    fi
    
    # Parse pools.yaml and create pools
    # This is a simplified version - you may want to use a Python script for complex logic
    log_info "Pool creation should be done via cephadm or manual commands"
    log_info "See deployment guide for pool creation steps"
    
    # Example: Create volumes pool
    # cephadm shell -- ceph osd pool create volumes 128 128
    # cephadm shell -- ceph osd pool set volumes device_class ssd
}

create_client_keys() {
    log_info "Creating Ceph client keys for OpenStack..."
    
    # Create cinder key
    cephadm shell -- ceph auth get-or-create client.cinder \
        mon 'allow r' \
        osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes' || {
        log_warn "Failed to create cinder key (may already exist)"
    }
    
    # Create glance key
    cephadm shell -- ceph auth get-or-create client.glance \
        mon 'allow r' \
        osd 'allow class-read object_prefix rbd_children, allow rwx pool=images' || {
        log_warn "Failed to create glance key (may already exist)"
    }
    
    # Create nova key
    cephadm shell -- ceph auth get-or-create client.nova \
        mon 'allow r' \
        osd 'allow class-read object_prefix rbd_children, allow rwx pool=vms' || {
        log_warn "Failed to create nova key (may already exist)"
    }
    
    log_info "Client keys created"
}

distribute_keys() {
    log_info "Distributing Ceph client keys to nodes..."
    
    # This should be done via Ansible playbook
    if [ -f "$PROJECT_ROOT/ansible/playbooks/distribute-ceph-keys.yml" ]; then
        ansible-playbook -i "$INVENTORY_DIR/hosts.yml" \
            "$PROJECT_ROOT/ansible/playbooks/distribute-ceph-keys.yml" || {
            log_error "Failed to distribute keys"
            exit 1
        }
    else
        log_warn "distribute-ceph-keys.yml playbook not found"
        log_warn "Keys must be distributed manually"
    fi
}

apply_deployment() {
    log_info "Starting Ceph deployment..."
    
    check_prerequisites
    validate_config
    bootstrap_cluster
    add_hosts
    apply_cluster_spec
    create_osds
    create_pools
    create_client_keys
    distribute_keys
    
    log_info "Ceph deployment completed"
    log_info "Check cluster status: cephadm shell -- ceph -s"
}

# Main
case "${1:-}" in
    --dry-run)
        dry_run
        ;;
    --apply)
        apply_deployment
        ;;
    *)
        echo "Usage: $0 [--dry-run|--apply]"
        echo ""
        echo "  --dry-run    Validate configuration without deploying"
        echo "  --apply      Deploy Ceph cluster"
        exit 1
        ;;
esac
