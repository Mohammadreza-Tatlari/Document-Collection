#!/bin/bash
# Configuration Backup Script
# Creates a backup of all configuration files
#
# Usage:
#   ./backup-config.sh [backup-dir]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BACKUP_DIR="${1:-$PROJECT_ROOT/backups/$(date +%Y%m%d-%H%M%S)}"

log_info() { echo "[INFO] $1"; }

log_info "Creating configuration backup..."
log_info "Backup directory: $BACKUP_DIR"

mkdir -p "$BACKUP_DIR"

# Backup inventory
log_info "Backing up inventory..."
cp -r "$PROJECT_ROOT/inventory" "$BACKUP_DIR/" 2>/dev/null || true

# Backup kolla configs
log_info "Backing up Kolla configuration..."
mkdir -p "$BACKUP_DIR/kolla"
cp "$PROJECT_ROOT/kolla/globals.yml" "$BACKUP_DIR/kolla/" 2>/dev/null || true
cp -r "$PROJECT_ROOT/kolla/config" "$BACKUP_DIR/kolla/" 2>/dev/null || true

# Backup Ceph configs
log_info "Backing up Ceph configuration..."
mkdir -p "$BACKUP_DIR/ceph"
cp "$PROJECT_ROOT/ceph/cluster-spec.yaml" "$BACKUP_DIR/ceph/" 2>/dev/null || true
cp "$PROJECT_ROOT/ceph/pools.yaml" "$BACKUP_DIR/ceph/" 2>/dev/null || true
cp -r "$PROJECT_ROOT/ceph/osd-specs" "$BACKUP_DIR/ceph/" 2>/dev/null || true

# Backup CI/CD config
log_info "Backing up CI/CD configuration..."
cp "$PROJECT_ROOT/.gitlab-ci.yml" "$BACKUP_DIR/" 2>/dev/null || true

# Create archive
log_info "Creating archive..."
tar -czf "$BACKUP_DIR.tar.gz" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")"
rm -rf "$BACKUP_DIR"

log_info "Backup completed: $BACKUP_DIR.tar.gz"
