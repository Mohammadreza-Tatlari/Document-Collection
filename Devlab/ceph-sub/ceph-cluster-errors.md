##

## Unknown Prometheus Errors in Dashboard 

### Problem explanation
The dashboard is keep sending the below Alert: 
```
0 - Unknown Error Http failure response for api/prometheus: 0 Unknown Error Http failure response for api/prometheus/rules: 0 Unknown Error A few seconds ago 
```
and
```
0 - Unknown Error Http failure response for ui-api/orchestrator/status: 0 Unknown Error
```

the ceph `ceph -s` status is okay but what can be the cuase?


### Reason of This Error:
**The root cuase of these two Errors are related to Browser not being able to connect to Backend**. but before that we can take alook over service as follow:


### Assumptions:
**what does those errors mean?** </br>
These come from the Ceph Dashboard frontend failing to talk to Prometheus through the mgr’s proxy endpoints.
- The dashboard does not talk directly to Prometheus
- It talks to ceph-mgr
- ceph-mgr then proxies requests to Prometheus

**The error can fall into:** </br>
- Prometheus container is not running
- Prometheus is running but unreachable from mgr
- mgr doesn’t know where Prometheus is
- mgr’s prometheus module is unhealthy or misconfigured


**`Http failure response for ui-api/orchestrator/status` - it can mean:**
- mgr daemon is unhealthy or restarting
- cephadm module is broken
- mgr lost state about managed services
- mgr cannot reach the container runtime (podman/docker)


### Diagnostics Steps

verify prometheus is running
- `ceph orch ps --daemon_type prometheus`


check mgr health
- `ceph mgr dump`
- `ceph mgr stat`

- `ceph mgr module ls` => check mgr modules (these modules should be on: dashboard, prometheus, orchestrator, cephadm) 
    - to enable modules: `ceph mgr module enable prometheus`
    - to enable modules: `ceph mgr module enable orchestrator`
    - ...

- `sudo cephadm ls | grep mgr` => find the active mgr node
- `sudo cephadm logs --name mgr.mohammadreza-ceph-srv1.wezlry` => check its logs

check whether server address and porst are present for prometheus
- `ceph config get mgr mgr/dashboard/PROMETHEUS_API_HOST`

test the URL via `curl`:
- `curl http://mohammadreza-ceph-srv1:9095/api/v1/status/runtimeinfo`

check the orchestration status:
- `ceph orch status`


**If all Service are Up and running then the Reason and the Error log will be proven.**






