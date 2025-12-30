# Design Level Practices -
“Design-level understanding” is a *good descriptive phrase*, but in the industry this way of thinking usually appears under more specific names, depending on culture:
- **System Design Thinking** – vague, often watered down
- **Architectural Reasoning** – closest academically
- **Design Rationale / Architecture Rationale** – when written well
- **Failure-oriented design** – SRE / resilience circles
- **Operational Architecture** – when ops is taken seriously
- **Second-order design** – informal but accurate
- **Intent-driven architecture** – modern cloud phrasing

What you are *actually practicing* is:
> **Architectural reasoning under operational and failure constraints**
> **Architecture design with explicit operational and failure assumptions**



# Pratice 1 - Desing Before Deploy For Devlab
before every project write a 2-3 Page Document to answer these questions:

## Goal of Project
A good “Goal of Project” survives technology changes. OpenStack, Ansible, Terraform should be replaceable without invalidating the goal.
If you can swap OpenStack with “$next_platform” and the goal still holds, you’re probably close to a real goal.

**diagnostic question (don’t skip this)** </br>
*What business or operational pain becomes impossible to tolerate if we do nothing for the next 18–24 months?* </br>
If you can’t answer that clearly, you’re not ready to write the document yet.

A very common (and often unconscious) mistake is to treat:“automation” or “cloud” as a goal. Neither is a goal. Both are tools to enforce constraints.

### Reframe the problem in terms of constraints
Design-level understanding starts by identifying constraints you are trying to enforce.
Typical hard constraints in your context (OpenStack + IaC) are:
- Provisioning time must drop from weeks → minutes
- Human access to infrastructure must be reduced
- Capacity must be pooled and schedulable
- Cost allocation / chargeback must become possible
- Vendor lock-in must be limited
- Workloads must move between environments with minimal redesign

After that Ask this: Which of these constraints are non-negotiable? </br>
That answer tells you the real goal.

Use this test. For each statement, ask whether it is true, false, or irrelevant to your project.


#### A practical litmus test to “be sure” (ask more questions)
Use this test. For each statement, ask whether it is true, false, or irrelevant to your project.

**Test A**

“If tomorrow we moved all workloads to a public cloud, this project would still be valuable.” </br>
- If true → your goal is **automation & standardization**
- If false → your goal is sovereign/private infrastructure control

**Test B**

“If we fully automated the current datacenter but kept ticket-based provisioning, this project would still succeed.” </br>
- If true → your goal is **operational efficiency**
- If false → your goal is self-service cloud consumption

**Test C**

“If users cannot consume infrastructure via API/CLI, the project has failed.”  </br>
- If true → you are explicitly building a cloud
- If false → you are doing infrastructure modernization

**Test D** ...

Answer these honestly. Don’t optimize for what sounds good.

**You are not merely automating a datacenter. You are aiming to change the operating model.**

That strongly points to this class of goal:
*Establishing a private (with optional hybrid extension) cloud that provides self-service, API-driven infrastructure while preserving on-prem control, predictability, and cost boundaries.* </br>
*Automation is mandatory, but it is subordinate.*

#### How to write the “Goal of Project” section correctly
*A strong goal section usually contains three layers:*

1. Primary goal (1–2 sentences, non-technical) </br>
*Example (adjust, don’t copy):* </br>
> The goal of this project is to transform the existing infrastructure into a cloud operating model that enables rapid, self-service provisioning of compute, storage, and networking resources while maintaining on-premise control, cost predictability, and regulatory compliance.

2. Explicit non-goals (this is critical) </br>
*Example:*
- This project is not intended to:
- Replicate public-cloud scale or feature velocity
- Eliminate all legacy systems in the first phase
- Optimize for maximum hardware utilization at the expense of reliability

3. Success criteria (observable, not KPIs yet) </br>
*Example:*
- Infrastructure can be provisioned via API without manual operator intervention
- Environment definitions are reproducible from version-controlled code
- Failure of individual nodes does not require manual recovery to restore service

A clear goal gives you the right to say: </br>
“Yes, this is worse in X, and we accept it because Y.”


### My Answer (Goal of Project):
To replace manual, operator-driven infrastructure changes with reproducible, policy-controlled workflows that can be executed on-demand, measured for cost, and delivered within minutes.

The goal of this project is to establish an infrastructure operating model in which routine infrastructure changes—such as virtual machine provisioning and network configuration—are executed through automated, reproducible workflows rather than direct human intervention.

The system must enable on-demand fulfillment of customer requests within minutes, while minimizing human error by enforcing changes through version-controlled definitions and predefined policies. Additionally, the infrastructure must produce reliable usage data to support internal chargeback or payback models based on actual resource consumption.

The project explicitly prioritizes operational correctness, repeatability, and cost accountability over feature completeness. It is not intended to introduce new service types beyond those historically delivered through manual processes, nor to fundamentally replace the existing ticketing system, although automation may be integrated into existing approval and request flows.

Human intervention in production is permitted only as a recovery mechanism, and must result in a corresponding change to the automation, configuration, or policy layer that prevents recurrence.




## Accounting Assumption
Accounting assumptions say what you’re willing to pay, forever. They are about what the system “counts,” what it ignores, and who pays the cost when reality diverges from the model. cost here, include Time, Risk, Complexity, Cognitive load, Failure blast radius and the Final is Money.

Accounting assumptions force you to surface hidden subsidies. If you don’t write them down, your system will still have them — just unconsciously.

#### Accounting Assumption Mental Model
Think of your system as having a ledger. for every action it asks:
who pays? when do they pay? what happens if they don't?

example 1: </br>
if human fixes production (manual fix):
with accounting assumption we will say: "*we incurred technical debt that must be repaid by updating automation.*"

example 2: </br>
if provisioning takes 3 days (Slow provisioning):
Is the cost paid by: costumer (waiting), operators (interruptions), Engineers (night works). </br>
*your design must decide who absorbs latency*

| Section                | Answers                                      |
| ---------------------- | -------------------------------------------- |
| Goal                   | What must be true if the project succeeds    |
| Architecture           | How the system is structured                 |
| Accounting Assumptions | Who pays the ongoing cost of keeping it true |

Architecture without accounting assumptions is fantasy.

#### If you don’t write accounting assumptions explicitly:
- Failures will default to human heroics
- Automation will slowly lose authority
- Your “cloud” becomes a scripted datacenter
- Everyone will think it’s someone else’s fault

#### My Answer (Accounting Assumption)
Automation is the source of truth. Any manual change that is not reflected in automation must cause automation to fail rather than silently accept drift.
- Infrastructure state is authoritative only when represented in automation artifacts. Automation debt is real debt
- Manual changes are unaccounted technical debt until encoded and Humans pay with engineering time, not operational stress
- Time spent encoding fixes is a required cost of operating the system
- Failed automation runs are an acceptable and expected signal of inconsistency
- Operational velocity is bounded by the speed of updating automation, not by human access




## Design Architecture
Design Architecture is not components. diagram or topology. Architecture answers to How does the system enforce the **goals and accounting assumptions under normal operation and failure. If your architecture does not make violating your accounting assumptions difficult, it is not real architecture.**

#### The Core of a Real architecture
A design architecture is valid only if it makes these three things unavoidable:
- Authority – who is allowed to change what
- Flow – how intent moves through the system
- State – where truth lives and how it is reconciled

#### Architecture vs Implementation
| Layer               | Question                                 |
| ------------------- | ---------------------------------------- |
| Design Architecture | *What must exist and how it must behave* |
| Implementation      | *Which software realizes it*             |

*Example:* </br>
- “There must be a single authoritative intent store” → architecture
- “Git + Terraform” → implementation

**Accounting Assumptions and Goals force certain architectural properties. You don’t get to choose them freely anymore.**


#### The minimal architecture for our scenario needs:
1. Intent Layer (What should exists) </br>
**Purpose**:</br>
Capture desired state, not actions

**Architectural requirement**:
- Declarative
- Versioned
- Reviewable
- Reproducible

Design Statement Example:
> All infrastructure changes originate from an explicit declaration of desired state stored in a version-controlled system. </br>
(no Git mentioned yet)


2. Control & Orchestration Layer (How intent is applied) </br>
**Purpose**:</br>
Translate intent into actions in a controlled, repeatable way.

**Architectural requirement**:
- Idempotent execution
- Failure must be explicit
- Partial success must be visible

Design Statement Example:
> Infrastructure reconciliation is performed by automated controllers that converge actual state toward declared intent and fail when divergence cannot be resolved safely.


3. Resource Authority Layer (Who actually owns resources) </br>
**Purpose**:</br>
Define who is allowed to mutate infrastructure.

**Architectural requirement**:
- APIs over shells
- RBAC is enforced at control plane
- Humans do not bypass policy casually

Design Statement Example:
> Direct mutation of infrastructure resources is restricted to controlled APIs; human access is limited to recovery operations. </br>
(This is where OpenStack fits — but don't say it yet.)


4. State & Drift Visibility Layer (What is real right now) </br>
**Purpose**:</br>
Make divergence observable and costly.

**Architectural requirement**:
- Actual state can be inspected
- Drift is detectable
- Drift is actionable

Design Statement Example:
> The system continuously compares declared and observed state and treats unaccounted divergence as a failure condition.


5. Consumption Interface (How users interact) </br>
**Purpose:** </br>
Prevent humans from becoming part of the control plane

**Architectural requirement**:
- Self-service
- Rate-limited
- Auditable
- Mapped to accounting

Design Statement Example:
> Users request infrastructure through standardized, auditable interfaces that map requests to resource ownership and usage accounting.

#### What a bad design architecture looks like
You’ll know you’re doing it wrong if your architecture section:
- Starts with “We use OpenStack, Ansible, Terraform”
- Lists services without authority boundaries
- Doesn’t say what happens on failure
- Assumes “operators will handle it”
- Treats humans as a reliability mechanism


### How to write a Design Architecture Section
#### 1. Architectural principles (5–7 bullets derived from Goal and Accounting Assumption) </br>
**Example:** </br>
- Automation is the sole authority for steady-state configuration
- Manual changes are temporary and must be reconciled
- Failure must be loud and attributable
...


#### 2. Logical layers (not physical)
This step should Describe Responsibilities, Boundaries and Guarantees. NOT hostnames, subnets and vendor SKUs.
1. Intent & Policy Layer (Source of Truth) </br>
Statement:
>The intent layer represents the authoritative declaration of infrastructure state and policy. Any infrastructure change not represented in this layer is considered temporary and invalid.

2. Orchestration & Reconciliation Layer </br>
Statement:
> Reconciliation mechanisms continuously converge actual infrastructure state toward declared intent and must fail when reconciliation would violate policy or encounter unaccounted divergence.

3. Infrastructure Control Plane </br>
Statement:
> Infrastructure resources are managed exclusively through controlled APIs that enforce identity, authorization, and policy, preventing direct mutation outside approved control paths.

4. Consumption & Request Interface
Statement: 
> Users consume infrastructure through standardized interfaces that translate approved requests into declarative intent, rather than direct operational actions.

5. Accounting & Metering Layer
Statement:
> Resource usage is continuously measured and attributed to consuming identities based on actual runtime state, independent of provisioning workflows.


#### 3. Control flow (normal & failure)
It **Explicitly** describes for example, How a VM is created, What happens if it fails halfway, Where humans may intervene. </br>
You must describe end-to-end flows. </br> 
**Example: VM Provisioning (normal operation)**
1. User submits request (ticket or self-service like a web UI)
2. Request is approved and translated into intent
3. Intent is committed to versioned store
4. Automation reconciles intent with infrastructure
5. Control plane provisions resources
6. Metering begins immediately
7. Result is reported back to requester

**Example: Manual recovery (failure & recovery) - This is where most architectures die. Yours must survive.**
1. Automation fails due to inconsistency
2. Human intervenes to restore service
3. Automation remains failed
4. Fix is encoded into intent or policy
5. Automation re-runs and succeeds
6. System returns to steady state



#### 4. State ownership table (Highly Recommended)
This table alone prevents half of future incidents. *Example:*:

| State                  | Authority     | Recovery                 |
| ---------------------- | ------------- | ------------------------ |
| Desired infrastructure | Intent layer  | Code change              |
| Runtime resource state | Control plane | Automated reconciliation |
| Emergency fixes        | Human         | Must be encoded          |





## Failure Scenario
A failure scenario is NOT a list of things that can go wrong, DR (Disaster Recovery) plan, incident runbook or postmortem. At design level, a failure scenario answers: </br>
**When something fails, which assumptions are violated, which part of the architecture absorbs the cost, and how authority is re-established?**

Example of Failure Scenario: </br>
*Manual Hotfix Causes Automation Drift*

### The structure of a decent failure scenario (use this ever time)
Every design-level failure scenario must contain exactly these sections:
1. Trigger (what broke) </br>
It should be Concrete, observable, boring. for example: </br>
> *A production VM experiences network misconfiguration. An operator manually modifies firewall rules directly on the host to restore connectivity.*

2. Violated assumption (this is the key step) </br>
You must tie the failure to **your accounting** or **architectural assumptions**. for example: </br>
> *Automation is the sole source of truth for steady-state infrastructure configuration.*

3. Immediate system behavior (no humans yet) </br>
What does the system do by design?
- Does automation stop?
- Does it retry?
- Does it lock state?
- Does it emit failure?

example: </br>
*Infrastructure continues running with the manual fix applied* </br>
*Automation reconciliation detects divergence between declared and actual state* </br>
*Subsequent automation runs fail explicitly due to unaccounted drift*


4. Human role (explicitly bounded). </br>
only now describe human involvement. If this is vague, your architecture is lying. you must say: </br>
- Who is allowed to act
- What they are allowed to touch
- What they are forbidden from doing

example: </br>
*Operator is permitted to perform manual changes only to restore service* </br>
*Operator is prohibited from marking the system “healthy” or bypassing automation failures*


5. Recovery vs Correction (separate them)
- Recovery = restore service
- Correction = restore architectural invariants

example: </br>
Recovery: </br>
*Service availability is restored via the manual firewall change*

Correction: </br>
*The firewall change is encoded into the intent and policy layer* </br>
*Automation definitions are updated and reviewed* </br>
*Automation reconciliation is re-executed* 

6. Post-condition (what must be true afterward) </br>
End every scenario with invariants restored. If you can’t state this, the scenario is incomplete </br>
*Automation runs succeed* </br>
*Declared and actual state converge* </br>
*No manual configuration remains unaccounted*

### Failure scenarios you must include for your project
At minimum, write scenarios for:

1. Automation fails mid-execution
2. Human performs emergency fix
3. Control plane API is partially unavailable
4. Metering data is delayed or missing
5. Intent is wrong but valid (most dangerous)


### How to practice **(this is the real skill)**
Take one **architectural invariant** and try to break it. Example: </br>
*“Automation is the source of truth”*

Then write: </br>
- 3 different ways it can be violated
- For each, who pays the cost
- For each, how authority is restored


Keep in Mind That Design-level Scenario ends with "**Architectural Authority is reostred**" NOT with "**Issue Resolved**"



## Trade Off


## Unconscious Decisions




