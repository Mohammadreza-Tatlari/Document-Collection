# Changing Cephadm Container Registry

### Pre-Registry Configuration Checks
1. first we need to check our default image repository:
- `ceph config get mgr mgr/cephadm/container_image_base` => it shows the base registry
<!-- - `ceph config get mgr mgr/cephadm/container_image_tag` => it shows the tag of images --> #wrong syntax - NEEDS REVISION
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
`ceph orch redeploy prometheus`
`ceph orch redeploy alertmanager`
`ceph orch redeploy grafana`
`ceph orch redeploy node-exporter`

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
