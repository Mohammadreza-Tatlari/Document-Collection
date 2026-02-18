# Runbook: Control plane or node failover

## Scope

Respond to failure of a control node or compute node: verify quorum, failover services, and optionally replace the node.

## Control node (controller-01) down

1. **Ceph:** If MON/MGR were on controller-01, quorum is still held by the other 2 MONs (compute-01, compute-02). Confirm: `ceph -s`; cluster should be healthy or degraded.
2. **OpenStack:** With a single control node (pilot), API and Horizon are unavailable until the node or VM is back. Restore the VM on Proxmox or bring the host back.
3. **Recovery:** Boot the controller (or restore from backup); run `kolla-ansible deploy` to ensure all services are up. Run `post-deploy` if needed.

## Compute node down

1. **Nova:** Instances on that node are down. Optionally evacuate (if shared storage) or leave for operator to restart after node is back.
2. **Ceph:** OSDs on that node are out; replication will rebalance. Run `ceph osd tree` and `ceph -s`; wait for recovery or replace the node (see add-node / replace-disk runbooks).
3. **Recovery:** Bring node back or commission a replacement; add to inventory and run deploy for that host.

## Single switch failure

The design has a single switch; if it fails, the whole fabric is down. Document and test failover when a second switch is added (e.g. MCLAG or STP).
