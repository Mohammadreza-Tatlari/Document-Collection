# 🛡️ SSH Bastion / Jump Server Documentation

**Host:** `sangar-v-srv1`\
**Private IP:** `172.31.11.21`\
**Purpose:** Secure gateway for SSH access to internal servers.

------------------------------------------------------------------------

# 📘 Table of Contents

1.  [Overview](#overview)\
2.  [Architecture](#architecture)\
3.  [Security Principles](#security-principles)\
4.  [Server Setup](#server-setup)\
5.  [User Management Model](#user-management-model)\
6.  [SSH Hardening](#ssh-hardening)\
7.  [Login Restrictions (nologin)](#login-restrictions-nologin)\
8.  [SSH Banner](#ssh-banner)\
9.  [ProxyJump (How users connect)](#proxyjump-how-users-connect)\
10. [Process for Adding a New User](#process-for-adding-a-new-user)\
11. [Process for a New User to
    Connect](#process-for-a-new-user-to-connect)\
12. [Internal Server Requirements](#internal-server-requirements)\
13. [Future Improvements](#future-improvements)

------------------------------------------------------------------------

# Overview

`sangar-v-srv1` is the central SSH bastion/jump host used to reach
internal servers.\
All user sessions must pass through this server using SSH ProxyJump,
ensuring:

-   centralized authentication\
-   clean audit logs\
-   no direct access to internal servers from user laptops\
-   no interactive shell on the bastion

This document explains the setup, purpose, and how users should use it.

------------------------------------------------------------------------

# Architecture

    Laptop → sangar-v-srv1 (Jump Server) → Internal Servers

-   Users authenticate to the bastion using SSH keys only.\
-   Bastion does not provide a shell (`/usr/sbin/nologin`).\
-   Users can only jump through to their target servers.\
-   ProxyJump tunnels traffic through the bastion automatically.

------------------------------------------------------------------------

# Security Principles

1.  No password login (SSH keys only).\
2.  No root login on bastion.\
3.  Users cannot obtain a shell on the bastion.\
4.  TCP forwarding is allowed (required for ProxyJump).\
5.  Bastion acts only as a tunnel, never as a workstation.\
6.  Each user has an isolated Linux account.\
7.  Banner displayed before authentication.

------------------------------------------------------------------------

# Server Setup

### Packages installed

``` bash
apt update && apt upgrade -y
apt install -y vim htop tmux nftables curl git fail2ban
```

### Groups created

``` bash
groupadd bastion-admins
```

------------------------------------------------------------------------

# User Management Model

Each administrator gets their own Linux user on the bastion:

-   unique username\
-   separate SSH key\
-   member of `bastion-admins`\
-   shell set to `/usr/sbin/nologin`\
-   NO interactive login

This ensures:

-   clean audit logs\
-   easy offboarding\
-   no shared accounts\
-   minimal attack surface

------------------------------------------------------------------------

# SSH Hardening

### Key SSH config changes (`/etc/ssh/sshd_config`)

``` text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowGroups bastion-admins
AllowTcpForwarding yes
X11Forwarding no
PermitTunnel no
GatewayPorts no
UseDNS no
LogLevel VERBOSE
Banner /etc/issue.net
```

### Why AllowTcpForwarding?

ProxyJump uses `-W host:port`, which requires TCP forwarding.\
Without this, jump access fails with:

    channel 0: open failed: administratively prohibited

------------------------------------------------------------------------

# Login Restrictions (nologin)

To prevent shell access:

``` bash
usermod -s /usr/sbin/nologin <username>
```

Result:

-   User can authenticate (needed for ProxyJump)\
-   User cannot get a shell\
-   Message shown: "This account is currently not available."

This is intentional and secure.

------------------------------------------------------------------------

# SSH Banner

Banner file: `/etc/issue.net`

Example:

    ====================================================
          This is the Bastion Server (sangar-v-srv1)
            Interactive logins are NOT allowed.
                     Please JUMP!! 🚀
    ====================================================

Enabled in `/etc/ssh/sshd_config`:

``` text
Banner /etc/issue.net
```

------------------------------------------------------------------------

# ProxyJump (How users connect)

Users configure `~/.ssh/config` on their own laptop.

Example:

``` sshconfig
Host sangar
    HostName 172.31.11.21
    User <bastion-username>
    IdentityFile ~/.ssh/id_ed25519

Host confluence
    HostName 172.31.11.23
    User ubuntu
    ProxyJump sangar
    IdentityFile ~/.ssh/id_ed25519
```

Then they connect using:

``` bash
ssh confluence
```

Flow:

    Laptop → sangar-v-srv1 → 172.31.11.23

------------------------------------------------------------------------

# Process for Adding a New User

### Admin steps:

1.  Receive user's public key (`id_ed25519.pub`).

2.  Create user:

``` bash
adduser <username>
usermod -aG bastion-admins <username>
usermod -s /usr/sbin/nologin <username>
```

3.  Install their SSH key:

``` bash
mkdir -p /home/<username>/.ssh
nano /home/<username>/.ssh/authorized_keys
chmod 700 /home/<username>/.ssh
chmod 600 /home/<username>/.ssh/authorized_keys
chown -R <username>:<username> /home/<username>
```

User can now authenticate but cannot obtain a shell.

------------------------------------------------------------------------

# Process for a New User to Connect

### User steps:

1.  Generate SSH key pair:

``` bash
ssh-keygen -t ed25519 -C "user@company"
```

2.  Send public key to admin.

3.  Add their public key to their own internal server into:

```{=html}
<!-- -->
```
    ~/.ssh/authorized_keys

4.  Create local SSH config:

``` sshconfig
Host sangar
    HostName 172.31.11.21
    User <username>
    IdentityFile ~/.ssh/id_ed25519

Host my-server
    HostName <target-ip>
    User <target-user>
    ProxyJump sangar
    IdentityFile ~/.ssh/id_ed25519
```

5.  Connect via:

``` bash
ssh my-server
```

------------------------------------------------------------------------

# Internal Server Requirements

For a user to SSH into an internal server:

1.  The server must accept SSH key authentication.\
2.  User's public key must be in the correct `authorized_keys`.\
3.  Optional: restrict access so only the bastion can reach SSH.

### Restricting SSH to bastion only:

`/etc/ssh/sshd_config` on internal server:

    AllowUsers ubuntu@172.31.11.21

Or via firewall:

    allow only 172.31.11.21 → tcp/22

------------------------------------------------------------------------

# Future Improvements

-   Restrict which servers each user can jump to\
-   Add Fail2ban protection\
-   Enable session recording (auditd, tlog)\
-   Manage users & SSH configs via Ansible\
-   Implement MFA on the bastion\
-   Separate HAProxy traffic from SSH traffic

------------------------------------------------------------------------

# End of Document
