# Devlab New Persepctive
about the Devlab project let me give you a view. it is a solid playground so treat it less like a lab and more like a small cloud company in miniature.

## Session 1 - A practical scenario that actually builds DevOps + infra maturity
you are building a small regional IaaS provider with strict hardware constraints and mixed disks.

### Core scenarios Tiered IaaS Cloud for SMEs
Target Imaginary customer:
- Small companies/Starups wants VMs, block storage, object storage. **Care about cost more than bleeding-edge performance** and Expect Reliability, not perfection.

#### Infrastructure roles (map for 6 servers)
Dont over-enginner, but don't go toy-mode either.
1. controller nodes (2-3)
    - openstack control plane (HA)
    - API, schedular, DB, message queue
2. Compute Nodes (2-3)
    - Nova Compute
    - No Ceph Mons Here if possible
3. Ceph Nodes
    - All nodes can contirbute OSDs
    - SSD for fast pool
    - HDD for capacity pool

**learn to live with imperfect placement, it force you to chase best practice diagram**


#### Storage Scenarios to pracice
where real devops skills grow
1. Tiered Ceph pools
    - SSD pool -> Cinder premium
    - HDD pool -> cinder standard 
    - RBD-backed volumes only at first ???
2. Failure-driven exercises
    - kill one OSD and observe rebalacing 
    - kill a MON and understand quorum
    - Fill HDD pool to 80% usage and watch performance collapse
3. Operational Policies
    - Pool-level replication choices 
    - Backfill throttling
    - Recovery vs client IO tradeoffs



### How to practice design-level alongside hands-on work (Pin an put expire date)
Design-level work must happen before and after every implementation step. not as documentation at the end.

#### Use a simple design loop and repeat it constantly
for every component (ceph, nova,neutron, etc) **answer these before touching ansible**:
1. Intent
    - Why does this component exist?
    - What user-facing capability does it enable?
    - what happens if its down?
2. Constraints
    - Hardware limits (mixed disks, limited nodes)
    - Skill limits (only you operating)
    - Business limits (cost, time)
3. Failure scenarios (non-negotiable) - Write explicitly, even you don't fix them yet.
    - If 1 disk dies what degrades?
    - If 1 node dies what breaks?
    - If a junior operator runs the wrong command, what's the blas radius?

This is the design-level thinking. after implenetation, **run post-design review**: </br>
once something is running ask:
- what assumption were wrong?
- what operational pain appeared?
- what would I change if this were production?

*Write short notes. thats your architecture intuition forming*


### Connecting this lab to future business thinking
the trick is to reuse the same work for both technical and business learning. </br>
learn to **treat every Component as a Product**
doing Infra engineering, cost modeling and MVP thinking all at once (Ceph-backend) </br>
forcing capacity planning, SLA thinking, Operational simplicity (MVP) </br>

1. Ceph-backend block storage
    - Customer problem: persistent VM disks
    - Value: reliability, snapshots
    - Cost drivers: Disks, replicatio, ops time
    - Risk: performance under load, recovery storms
2. Define a fake but realistic MVP
    - not openstack cloud but "**VM + block storage for 10 small companies, max 50 VMs total**" </br>
*your design should explain why it survies this MVP otherwise its not ready.*


### STEPS: Diving in together
steps should be worked **iteratively** not in theory
1. step 1 - We lock down:
    - Exact node roles
    - Network layout (mgmt/storage/tenant)
    - Ceph topology (OSDs per node, pools)
2. step 2 - Before deploy
    - write failure scenarios for
        - 1 disk loss
        - 1 node loss
        - operator mistake
3. Step 3 - Deploy with kolla-ansible
    - minimal service first
    - No "enable everyting"
4. Step 4 - Break it on purpose
    - Obeserve
    - Redesign
    - Repeat ???



## Session 2 - design decision for 6 Servers (Primary leading goal: Automation discipline)
automation discipline only emerges when the system is intentionally constrained. we need to structure this in four layers:
1. what kind of cloud you are actually building (scenario refinement)
2. Concrete design: network, storage, node roles
3. How to force automation discipline (avoid "hero ops")
4. How juniors fit into this without breaking everything

### 1. Refined scenario: What you are really buidling?
with given mixed disks, 1G networking, small team + juniors and automation as primary goal. **we are not building a performance cloud, we are building an operations-first cloud**. think: if your cloud service can survive humans.

the Internal scenario/mindset should be: </br>
"**A small IaaS platfomr operated by a team where manual fixes are considered failures**"


### 2. Concrete Design: no abstraction

#### 2.1 Network Design (simple, boring, automatable)

| VLAN | Purpose           | Why                      |
| ---- | ----------------- | ------------------------ |
| 110  | Management + API  | Everything depends on it |
| 111  | Storage (Ceph)    | Isolate noisy IO         |
| 112  | Tenant / Provider | Future growth            |


1. Rules (Imporatant)
    - One bonded interface, VLAN sub-interfaces
    - No srvice talks over the wrong vlan
    - No "temporary shortcuts
2. Mapping
    - Kolla interval IP -> VLAN 110
    - Ceph MONs/OSD traffic -> VLAN 111
    - Neutron provider network -> VLAN 112

vlan 112 can become our first controlled failure later.


#### 2.2 Node roles (resist symmetry)
6 servers exists but they are not going to be treated equally:

Propose Roles:
| Node   | Role                        |
| ------ | --------------------------- |
| Node 1 | Controller + Ceph MON + OSD |
| Node 2 | Controller + Ceph MON + OSD |
| Node 3 | Controller + Ceph MON + OSD |
| Node 4 | Compute + OSD               |
| Node 5 | Compute + OSD               |
| Node 6 | Compute + OSD               |

- MON quorum surives 1 node loss
- Control plane surives 1 node loss
- Junior breaking a compute node won't cause outage


#### 2.3 Ceph design (where discipline is tested)
1. OSD strategy
    - All data disks are OSDs
    - OS disk never touches Ceph
    - no manual OSD creation - only ansible
2. Pools (keep it minimal)
    - `rbd_ssd`
        - backed by SSD OSDs only
        - Replciation 2 (not 3 because we are low on SSD)
    - `rbd_hdd`
        - backed by HDD OSDs
        - replication: 3
3. No EC pools yet
    - they complicate ops and junior mistakes multiply
4. CRUSH rules ([CRUSH MAP](https://docs.ceph.com/en/mimic/rados/operations/crush-map/?utm_source=chatgpt.com)) - ([Editing the CRUSH MAP](https://docs.ceph.com/en/latest/rados/operations/crush-map-edits/?utm_source=chatgpt.com)) - [Manual Doc](./ceph-sub-topics/ceph-disk-ssd-hdd-CRUSH.md)
    - Separate CRUSH rules from SSD vs HDD
    - Failure Domain: host, not disk

If availability can be destroyed by unplugging one server, the design failed.


### 3. Forcing automation discipline
**automation discipline is making manual work useless or dangerous**, not using ansible.

#### 3.1 Golden rule
"**If a change cannot be reproduced by automation, it is forbidden**"

* The golden rule applies to:
    - Network changes
    - Ceph config
    - OpenStack config
    - Node onboarding


#### 3.2 Mandatory patterns you must enforce
1. Immutable-ish mindset
    - Nodes are replaceable
    - Rebuild beats repair
    - "SSH fix" is a last restort and documented as a failure
2. One source of truth
    - Git repo (**IMPORTANT**)
        - netplan config
        - kolla globals
        - inventory
    - no config drift tolerated (Git should always win if reality is not equal to Git)
3. Break things on schedule - you must schedule failure:
    - Kill an OSD during work hours
    - Reboot a controller
    - Misconfigure neutron on purpose

if automation can't recover, its lying.


### 4. Using juniors as a design tool 
Juniors are not just learners, they are chaos generators.

#### Control Responsibility ladder
1. Read-only
    - logs
    - dashboards-
2. Runbooks only
    - follow this exactly
3. one-click automation
    - playbooks
4. design review
    - explain why his won't break prod


### 5. Design-level pratice
for every subsystem, you must write three things before deployment:
1. Intent
    - What problem does this solve?
2. Failure Scenario
    - Disk dies
    - Node dies
    - Human error
3. Operational response
    - who notices?
    - what breaks?
    - How is it recovered?


### STEPS: Before installation 

1. Step A - Write a 1-page design with these sections:
    - Network layout
    - node roles
    - ceph pools
    - failure assumptions
2. Step B - Define 3 non-negotiable failure scenarios, examples:
    - one controller powered off at 14:00
    - one SSD OSD fails during rebuild
    - Junir mis-tags a VLAN
3. Step B - Decide what must not happen, examples:
    - No manual Ceph commands
    - No config changes outside Git
    - No single node causes full outage

