# Ansible – Base OS and shared config

Playbooks for base OS hardening: users, SSH keys, firewall, NTP, DNS client. Run from a deploy host with SSH access to all nodes on the management subnet (VLAN 110).

**Requirements:** `ansible` (2.14+), `community.general` collection (`ansible-galaxy collection install community.general`). For DNS via resolvconf, install the `resolvconf` package on targets; on Ubuntu 24.04 you may prefer to set DNS in netplan instead.

## Layout

- `inventory/` – Inventory and group_vars (do not commit secrets; use vault or separate vault file).
- `playbooks/` – Site and role-calling playbooks.
- `roles/` – Optional roles (or inline tasks in playbooks).

## Usage

```bash
# Install Ansible and run (example)
ansible-playbook -i inventory/hosts.yml playbooks/site-base-os.yml
```

Use `--ask-vault-pass` or vault password file when using Ansible Vault for `passwords.yml` or group_vars.
