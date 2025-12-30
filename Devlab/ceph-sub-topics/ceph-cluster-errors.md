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




## Removing an image with protected snapshot

In RBD, a **protected snapshot** exists because it is (or may be) used as a **parent** for one or more cloned images.

Ceph guarantees that:
- A snapshot **cannot be deleted** if any image depends on it.
- Protection is the explicit mechanism that enforces this guarantee.

So your purge failed because at least one snapshot of that image is:
1. **Protected**
2. Possibly **has children (clones)**

Until both conditions are resolved, Ceph refuses to proceed.


### Correct deletion workflow (step-by-step, with rationale)

#### 1. List snapshots on the image

First, identify *exactly* which snapshots exist and which are protected.

```bash
rbd snap ls images/4e158efd-6b72-4eae-8306-b559135760e6
```

You’ll see something like:

```
SNAPID  NAME        SIZE    PROTECTED
123     snap        10 GiB  yes
```

This tells you:

- Snapshot name
- Whether it’s protected (this is the blocker)


#### 2. Check whether the snapshot has children (critical step)

A snapshot can only be unprotected **if it has no children**.

```bash
rbd children images/4e158efd-6b72-4eae-8306-b559135760e6@snap
```

Possible outcomes:
- **No output** → safe to unprotect
- One or more images listed which it means, those images depend on this snapshot

This is the most commonly skipped step, and the one that causes confusion later.



#### 3. If there are children: decide how to break the dependency
You have two legitimate options:

##### Option A: Delete the child images

If the clones are no longer needed:

```bash
rbd rm images/<child-image>
```
Repeat until `rbd children` shows nothing.

#### Option B: Flatten the child images **(more common in production)**

Flattening makes the clone independent of the parent snapshot.

```bash
rbd flatten images/<child-image>
```

After flattening:

- The child no longer depends on the snapshot
- The snapshot can now be unprotected

This is usually the **correct choice** when images are still in use.

---

### 4. Unprotect the snapshot

Once there are no children:

```bash
rbd snap unprotect images/4e158efd-6b72-4eae-8306-b559135760e6@snap
```

At this point, you’ve removed Ceph’s safety lock.

---

### 5. Purge snapshots

Now the purge will succeed:

```bash
rbd snap purge images/4e158efd-6b72-4eae-8306-b559135760e6
```

This removes **all snapshots** on the image.

---

### 6. (Optional but typical) Remove the image itself

If your end goal is full cleanup:

```bash
rbd rm images/4e158efd-6b72-4eae-8306-b559135760e6
```


emphasized chain:
> **Clone → Snapshot → Protection**

- Snapshots are protected **because** clones exist
- Protection is not a permission issue, it’s a **data dependency issue**
- The fix is always to resolve dependencies, never to “force delete”

If you ever find yourself thinking *“Ceph should just let me delete this”*, that’s a signal you haven’t fully mapped the dependency graph yet.





---
## How to remove an Active Router in Openstack 

1. Identify its port:
- `openstack router list`
- `openstack port list`
- `openstack port show <ID> -c device_owner`
- `openstack port show <ID>`

2. remove its subnet id (if it is active)
- `openstack router remove subnet <router-name> <subnet-id>`

3. finally remove the router
- `openstack router delete <router-name>`




This error is not incidental; it’s Neutron enforcing a **hard lifecycle rule**. A router is not a free-standing object. If it still owns *any* ports, deletion is forbidden. The message is already telling you exactly what’s blocking it.

Let's unpack this cleanly and precisely.



### 1. What Neutron is really saying

```
Router ... has ports still attached: d850454b-4185-4e7a-88de-52269d59ec22
```

That port is almost certainly **one of these**:

* a router interface to a tenant subnet (`qr-*`)
* a router gateway port (`qg-*`) to the external network

Neutron routers always have **at least one internal port** once you attach a subnet, and optionally **one external gateway port**.

Deletion order is **strict**:

1. Detach all interfaces (internal ports)
2. Remove external gateway (if set)
3. Delete router

Anything else is invalid.

---

### 2. Identify exactly what port that is

Do not guess. Ask Neutron.

```
openstack port show d850454b-4185-4e7a-88de-52269d59ec22
```

You’ll see fields like:

* `device_owner`
* `fixed_ips`
* `network_id`

Key values:

* `device_owner = network:router_interface` → internal subnet
* `device_owner = network:router_gateway` → external gateway

This tells you **which removal step is required**.



### 3. Correct teardown sequence (authoritative)

#### 3.1 If it’s an internal subnet interface

Find the subnet:

```
openstack port show d850454b-4185-4e7a-88de-52269d59ec22 -f value -c fixed_ips
```

Then remove it:

```
openstack router remove subnet first-router <subnet-id>
```

Neutron will delete the router port automatically.



#### 3.2 If it’s the external gateway

Remove the gateway:

```
openstack router unset --external-gateway first-router
```

This deletes the `qg-*` port.



### 4. Verify router is clean

Before retrying deletion, verify:

```
openstack router show first-router -f yaml
```

You should see:

* no `interfaces_info`
* `external_gateway_info: null`

Only then:

```
openstack router delete first-router
```



### 5. Why Neutron enforces this (important)

This isn’t arbitrary.

Neutron routers map to **real Linux namespaces** and **real OVS ports**:

* Internal interface → `qr-XXXX` (veth into `qrouter-*`)
* Gateway interface → `qg-XXXX` (connected to `br-ex`)

Deleting a router with live ports would:

* orphan namespaces
* leak iptables rules
* leave dangling OVS ports

So Neutron refuses the operation at the API layer.



### 6. Common mistakes to avoid

* ❌ Trying to delete router first
* ❌ Manually deleting OVS ports (`ovs-vsctl del-port`)
* ❌ Deleting Neutron ports directly (`openstack port delete`)

Neutron owns these objects. If you bypass it, you corrupt state.



### 7. Mental model to keep

```
Subnet ──► Router ──► External network
   ▲           ▲
   │           │
 remove first  remove second
```

Only after **both sides are detached** does the router become deletable.



If you want, next we can:

* Walk through **router teardown all the way down to OVS**
* Trace how Neutron decides which ports block deletion (code-level)
* Or simulate a broken router state and recover it safely

Pick the direction.
