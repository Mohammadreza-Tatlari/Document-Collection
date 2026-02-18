# Troubleshooting Guide

Common issues and solutions for OpenStack + Ceph deployment.

## General Debugging

### Check Service Status

```bash
# OpenStack services
docker ps | grep -E "nova|neutron|cinder|glance|keystone"

# Ceph services
cephadm shell -- ceph -s
cephadm shell -- ceph orch ps
```

### Check Logs

```bash
# Kolla-Ansible logs
tail -f /var/log/kolla/<service>/<service>.log

# Docker logs
docker logs <container-name>

# Ceph logs
cephadm shell -- ceph log last <service>
```

## OpenStack Issues

### Services Not Starting

**Symptoms**: Containers exit immediately or fail to start

**Solutions**:

1. Check configuration syntax:
   ```bash
   kolla-ansible -i inventory/production/hosts.yml prechecks
   ```

2. Check Docker logs:
   ```bash
   docker logs <container-name>
   ```

3. Verify network connectivity:
   ```bash
   ansible all -i inventory/production/hosts.yml -m ping
   ```

4. Check disk space:
   ```bash
   df -h
   ```

### Keystone Authentication Failures

**Symptoms**: Cannot authenticate, 401 errors

**Solutions**:

1. Verify admin credentials:
   ```bash
   source /etc/kolla/admin-openrc.sh
   openstack token issue
   ```

2. Check Keystone logs:
   ```bash
   docker logs kolla_keystone_api
   ```

3. Verify database connectivity:
   ```bash
   docker exec -it kolla_mariadb mysql -u root -p
   ```

### Nova Compute Issues

**Symptoms**: VMs not starting, compute nodes not registering

**Solutions**:

1. Check compute node registration:
   ```bash
   openstack hypervisor list
   ```

2. Verify libvirt:
   ```bash
   docker exec -it kolla_nova_compute systemctl status libvirtd
   ```

3. Check Nova logs:
   ```bash
   docker logs kolla_nova_compute
   ```

### Neutron Networking Issues

**Symptoms**: VMs cannot get IPs, network creation fails

**Solutions**:

1. Check Neutron agents:
   ```bash
   openstack network agent list
   ```

2. Verify bridge configuration:
   ```bash
   brctl show
   ip link show
   ```

3. Check iptables rules:
   ```bash
   iptables -L -n
   ```

### Cinder Volume Issues

**Symptoms**: Cannot create volumes, volumes stuck in creating

**Solutions**:

1. Check Cinder service status:
   ```bash
   openstack volume service list
   ```

2. Verify Ceph connectivity:
   ```bash
   cephadm shell -- ceph -s
   ```

3. Check Cinder logs:
   ```bash
   docker logs kolla_cinder_volume
   ```

4. Verify Ceph client keys:
   ```bash
   cephadm shell -- ceph auth list | grep cinder
   ```

## Ceph Issues

### OSDs Not Starting

**Symptoms**: OSDs down, cluster unhealthy

**Solutions**:

1. Check OSD status:
   ```bash
   cephadm shell -- ceph osd tree
   cephadm shell -- ceph osd df
   ```

2. Check OSD logs:
   ```bash
   cephadm shell -- ceph log last osd.<osd-id>
   ```

3. Verify disk availability:
   ```bash
   cephadm shell -- ceph orch device ls
   ```

4. Restart OSD:
   ```bash
   cephadm shell -- ceph orch daemon restart osd.<osd-id>
   ```

### Pool Creation Failures

**Symptoms**: Cannot create pools, PG errors

**Solutions**:

1. Check PG count:
   ```bash
   cephadm shell -- ceph pg stat
   ```

2. Verify device classes:
   ```bash
   cephadm shell -- ceph osd crush tree
   ```

3. Adjust PG count if needed:
   ```bash
   cephadm shell -- ceph osd pool set <pool> pg_num <value>
   ```

### Ceph Client Authentication Failures

**Symptoms**: OpenStack cannot access Ceph pools

**Solutions**:

1. Verify client keys exist:
   ```bash
   cephadm shell -- ceph auth list | grep -E "cinder|glance|nova"
   ```

2. Check key permissions:
   ```bash
   ls -la /etc/ceph/ceph.client.*.keyring
   ```

3. Regenerate keys if needed:
   ```bash
   cephadm shell -- ceph auth get-or-create client.cinder \
     mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes'
   ```

## Network Issues

### SSH Connection Failures

**Symptoms**: Cannot SSH to nodes from deploy-node

**Solutions**:

1. Verify SSH keys:
   ```bash
   ssh-copy-id -i ~/.ssh/id_ed25519.pub deploy@<node>
   ```

2. Test SSH:
   ```bash
   ssh deploy@<node> 'hostname'
   ```

3. Check firewall:
   ```bash
   sudo ufw status
   ```

### Network Interface Issues

**Symptoms**: Wrong interface used, network not accessible

**Solutions**:

1. List interfaces:
   ```bash
   ip link show
   ```

2. Update inventory:
   ```bash
   # Edit inventory/production/hosts.yml
   # Update network_interface, neutron_external_interface, etc.
   ```

3. Verify interface configuration:
   ```bash
   cat /etc/netplan/*.yaml
   ```

## Deployment Issues

### Kolla-Ansible Failures

**Symptoms**: Deployment fails at specific task

**Solutions**:

1. Check task output:
   ```bash
   # Re-run with verbose output
   kolla-ansible -i inventory/production/hosts.yml deploy -vvv
   ```

2. Check specific service:
   ```bash
   kolla-ansible -i inventory/production/hosts.yml deploy --tags nova
   ```

3. Check prechecks:
   ```bash
   kolla-ansible -i inventory/production/hosts.yml prechecks
   ```

### GitLab CI/CD Failures

**Symptoms**: Pipeline jobs failing

**Solutions**:

1. Check job logs in GitLab UI
2. Verify runner connectivity:
   ```bash
   # On deploy-node
   gitlab-runner verify
   ```

3. Check runner logs:
   ```bash
   sudo journalctl -u gitlab-runner -f
   ```

4. Verify SSH access from runner:
   ```bash
   # Test from runner context
   ansible all -i inventory/production/hosts.yml -m ping
   ```

## Performance Issues

### Slow VM Creation

**Symptoms**: VMs take long time to start

**Solutions**:

1. Check compute node resources:
   ```bash
   openstack hypervisor show <hypervisor>
   ```

2. Check Ceph performance:
   ```bash
   cephadm shell -- ceph osd perf
   ```

3. Verify image location:
   ```bash
   # Ensure images are in fast SSD pool
   cephadm shell -- ceph osd pool ls detail
   ```

### Slow Volume Operations

**Symptoms**: Volume creation/attachment slow

**Solutions**:

1. Check Ceph pool performance:
   ```bash
   cephadm shell -- ceph osd pool get volumes all
   ```

2. Verify using SSD pool:
   ```bash
   cephadm shell -- ceph osd crush tree
   ```

3. Check Cinder backend:
   ```bash
   openstack volume service list
   ```

## Getting Help

### Information to Collect

When reporting issues, include:

1. **Error Messages**: Full error output
2. **Logs**: Relevant service logs
3. **Configuration**: Relevant config files (sanitized)
4. **Environment**: OpenStack release, Ceph version, OS version
5. **Steps to Reproduce**: What you did before issue occurred

### Escalation Path

1. **Check Documentation**: This guide, architecture docs
2. **Search Issues**: GitLab issues for similar problems
3. **Ask Team**: GitLab Discussions or team chat
4. **Senior Engineer**: For critical production issues

## Prevention

### Regular Maintenance

1. **Monitor**: Set up Prometheus/Grafana alerts
2. **Backup**: Regular database and config backups
3. **Update**: Keep OpenStack and Ceph updated
4. **Review**: Regular code and config reviews
5. **Test**: Test changes in staging first

### Best Practices

1. **Document Changes**: Update docs with config changes
2. **Version Control**: Tag releases for tracking
3. **Gradual Rollout**: Deploy changes incrementally
4. **Monitor Closely**: Watch metrics after deployments
5. **Have Rollback Plan**: Know how to revert changes
