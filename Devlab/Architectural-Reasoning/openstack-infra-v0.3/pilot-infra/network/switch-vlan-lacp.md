# Switch Configuration: LACP + VLANs 110, 111, 112

Document your switch config here. Below is a generic template; adapt to your vendor (Cisco, Arista, etc.).

## Per-server port-channel (LACP)

- For each of the 6 servers, assign 3 physical ports to a single **port-channel** (EtherChannel / LAG).
- Mode: **802.3ad** (LACP) active.
- All 3 VLANs (110, 111, 112) must be **tagged** on the port-channel (trunk).

## VLAN definitions

- **VLAN 110** – 172.31.10.0/24 (management)
- **VLAN 111** – 172.31.11.0/24 (Ceph)
- **VLAN 112** – 172.31.12.0/24 (tenant)

## Example (Cisco-style)

```
vlan 110
 name management
vlan 111
 name ceph
vlan 112
 name tenant

interface range gi1/0/1-3
 channel-group 1 mode active
interface port-channel 1
 switchport mode trunk
 switchport trunk allowed vlan 110,111,112
```

Repeat `channel-group` and `port-channel` for each server (e.g. port-channel 2 for server 2, etc.). Use your actual port numbers.

## ILO

ILO addresses 172.26.1.101–106 are reachable from VLANs 110, 111, 112. For hardening, consider a dedicated management VLAN and ACLs later.

## NTP

Configure the switch to use the same NTP server(s) as the servers (required for Ceph and OpenStack).
