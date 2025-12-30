# Changing Cephadm Container Registry

### Pre-Registry Configuration Checks
1. first we need to check our default image repository:
- `ceph config set mgr container_image reg.abrvand.ir/quay.io`
- `ceph config get mgr mgr/cephadm/container_image_base` => it shows the base registry
- `ceph config get mgr mgr/cephadm/container_image_node_exporter`  #it might not be beginning of deployment so it shout be `set`
- `ceph config get mgr mgr/cephadm/container_image_prometheus` #it might not be beginning of deployment so it shout be `set`
- `ceph config get mgr mgr/cephadm/container_grafana` #it might not be beginning of deployment so it shout be `set`
- `ceph config get mgr mgr/cephadm/container_image_alertmanager` #it might not be beginning of deployment so it shout be `set`

2. check your current ceph version (**it will be used for registry taging**)
- `ceph -v`


### Setting New Registry
In this step, registry and image directory of each service is explicitly define with **its version** keep in mind that `:latest` versioning is highly discouraged. for lack of inconsistency in versioning.

1. change the registry by:
- `ceph config set mgr mgr/cephadm/container_image_base <reg.abrvand.ir/quay.io>`
- `ceph config set mgr mgr/cephadm/container_image_prometheus reg.abrvand.ir/quay.io/prometheus/prometheus:v2.51.0`
- `ceph config set mgr mgr/cephadm/container_image_alertmanager reg.abrvand.ir/quay.io/prometheus/alertmanager:v0.25.0`
- `ceph config set mgr mgr/cephadm/container_image_grafana reg.abrvand.ir/quay.io/ceph/grafana:10.4.0`
- `ceph config set mgr mgr/cephadm/container_image_node_exporter reg.abrvand.ir/quay.io/prometheus/node-exporter:v1.7.0`

verify it: 
- `ceph config get mgr mgr/cephadm/container_image_base`
- `ceph config dump | grep container_image`


### Redeploy daemons to apply changes

1. redeploy services (this process can take time)
- `ceph orch redeploy prometheus`
- `ceph orch redeploy alertmanager`
- `ceph orch redeploy grafana`
- `ceph orch redeploy node-exporter`

verify it on docker engine: </br>
- `docker ps -a`


2. if Ceph `mgr`,`mon`,`osd` also need to be re-deployed (not mandatory and needs revision)
    1. re-deploy mgr first
    - `ceph orch redeploy mgr`
    2. re-deploy mons
    - `ceph orch redeploy mon`
    3. re-deploy OSDs
    - `ceph orch redeploy osd`


#### Redeploy Per Hosts
1. if you have multiple host in cluster and deployment are not scheduled on them:
- `ceph orch host redeploy <hostname>` </br>
monitor re-deploy process:
- `ceph orch ps`


#### Verify Running Containers
- `docker ps --format "{{.Image}}"`


### Handle private registry authentication (if needed)
1. login to your registry
- `docker login reg.abrvand.ir`

note: If auth is missing
- Daemons will fail with `ImagePullError`
- ceph orch will keep retrying


### Rollback (if something goes wrong)
- `ceph config set mgr mgr/cephadm/container_image_base quay.io`
- `ceph orch redeploy mgr`
- `ceph orch redeploy mon`
- `ceph orch redeploy osd`


### Additional Thoughts
Mirroring quay.io is the right move in restricted or high-latency environments, but it adds operational burden:
- You now own image freshness
- Security CVEs won’t magically update

If this is production, you should pair this with:
- A scheduled mirror sync
- Explicit upgrade workflows


---
# Changing Docker Registry in Kolla Ansible ([Deploy a Registry](https://docs.openstack.org/kolla-ansible/2023.1/user/multinode.html#deploy-a-registry))

- 1. changing `globals.yml` key values as follow:

```yaml
docker_registry: reg.abrvand.ir/quay.io
#docker_registry_insecure: false
```

2. redeploy the kolla-ansible cluster

- `kolla-ansible reconfigure -i all-in-one`



--- 

1. Set the Global Container Image
- `ceph config set global container_image reg.abrvand.ir/quay.io/ceph/ceph:v19.2.3`


2. Initiate the Upgrade
- `ceph orch upgrade start --image reg.abrvand.ir/quay.io/ceph/ceph:v19.2.3`

3. Monitor the Progress
- `ceph orch upgrade status`







## Where `--image` actually exists

### 1. `cephadm bootstrap` (day-0 only)

This is the most common place people remember it from.

```bash
cephadm bootstrap \
  --image reg.abrvand.ir/ceph/ceph:v18.2.0 \
  --mon-ip <IP>
```

**What it does**

* Defines the *initial* Ceph image
* Used only at bootstrap time
* Stored into the cluster config as the default image

**What it does NOT do**

* It cannot be used after the cluster is up
* It does not update running daemons

This is usually where the memory comes from.

---

### 2. `ceph orch apply … --image` (service-level override)

This is the **post-bootstrap** usage, but it is *per service*, not global.

Example:

```bash
ceph orch apply mgr --image reg.abrvand.ir/ceph/ceph:v18.2.0
```

or:

```bash
ceph orch apply prometheus \
  --image reg.abrvand.ir/ceph/prometheus:v2.45.0
```

**Key characteristics**

* Overrides the image **for that service only**
* Triggers redeploy of that service
* Does not change the global default registry
* Survives restarts but not necessarily upgrades unless reapplied

This is the *only* supported way to “update image” live without touching config keys.

---

### 3. `ceph orch daemon redeploy <daemon> --image` (granular control)

Less commonly used, but exists:

```bash
ceph orch daemon redeploy mgr.mohammadreza-ceph-srv1 \
  --image reg.abrvand.ir/ceph/ceph:v18.2.0
```

This is:

* Per-daemon
* Surgical
* Useful for testing a mirrored image before rolling it out

---

## What does NOT exist (and never did)

There is **no** command like:

```bash
ceph orch update --image …
```

or

```bash
ceph orch set --image …
```

for the whole cluster.

If you remember something that *felt* like that, it was almost certainly:

* `cephadm bootstrap --image` **or**
* `ceph orch apply <service> --image`

---

## Why Ceph split registry vs image flags (design reasoning)

This is intentional and non-accidental:

| Mechanism                  | Purpose                         |
| -------------------------- | ------------------------------- |
| `container_image_registry` | Policy (where images come from) |
| `--image` flags            | Execution (what to run *now*)   |

Ceph forces you to:

* Set **policy** via config
* Trigger **action** via redeploy/apply

That separation is why live clusters don’t unexpectedly restart.

---

## Practical rule of thumb

* **Want everything to move over time?**
  → `ceph config set mgr mgr/cephadm/container_image_registry …`

* **Want something to change now?**
  → `ceph orch apply … --image`

* **Testing / debugging one daemon?**
  → `ceph orch daemon redeploy … --image`

