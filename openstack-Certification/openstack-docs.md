
### Openstack core mechanism
OpenStack is a cloud operating system that controls large pools of compute, storage, and networking resources throughout a datacenter, all managed and provisioned through APIs with common authentication mechanisms. There are OpenStack CLI tools and SDKs giving operators the flexibility to create OpenStack cloud applications in the language of their choice. Supported languages include Go, Python, Ruby, and Java. Beyond standard infrastructure-as-a-service functionality, additional components provide orchestration, fault management and service management amongst other services to provide operators flexibility to customize their infrastructure and ensure high availability of user applications.

OpenStack’s modular framework allows you to identify and deploy components depending on your needs. The OpenStack map gives you a high level overview of the OpenStack landscape to see where those services fit and how they can work together.

![openstack-map](../media/openstack-map-v20250401.svg)


### Services in Openstack

#### 2.3 RESTful API 
Inter-Service Communication - The standard way all OpenStack services communicate with each other and with external applications. They are defined for each project (Nova API, Neutron API, etc.) to allow for modularity and integration. By using standard HTTP methods (GET, POST, PUT, DELETE) and JSON or XML data formats, the APIs ensure all services are modular, interoperable, and accessible programmatically, which is fundamental to building an automated cloud platform.

#### 2.3 Nova
Compute - Manages the lifecycle of virtual machine (VM) instances (creation, scheduling, deletion). It's the central engine for on-demand compute resources. Uses **Flavors** (predefined sizes for CPU, RAM, and disk) to allocate resources and interacts with Glance to get the base OS image and Neutron for networking.

#### 2.4 Swift
Object Storage - Provides a highly scalable, distributed, and durable object storage system for unstructured data (e.g., files, backups, and static content). It achieves high availability and data integrity through extensive data replication across multiple server nodes, making it suitable for data that needs to grow indefinitely and withstand hardware failures

#### 2.5 Neutron
Networking - Delivers Networking-as-a-Service by managing virtual networks, subnets, routers, and security groups to connect the compute instances. It completely isolates tenant networks, enabling users to build complex, customized network topologies for their applications without direct concern for the underlying physical network hardware.

#### 2.6 Glance
Image Service - Serves as a registry and repository for storing, discovering, and retrieving virtual machine disk images (OS templates) used to provision Nova instances. It manages image metadata (size, format, minimum required memory, etc.) and is often configured to store the actual image files in a scalable storage backend like **Swift** (Object Storage).

#### 2.7 Cinder
Block Storage - Provides persistent, high-performance block storage volumes that can be attached to running VMs, like a virtual hard drive. It is responsible for virtualizing block storage devices and features a pluggable driver architecture that allows it to integrate with various backend storage systems (e.g., Ceph, LVM, commercial storage arrays). 

#### 2.8 Horizon
Dashboard - The web-based graphical user interface (GUI) that users and administrators use to interact with and manage the various OpenStack services. All actions performed in Horizon are ultimately translated into API calls to the corresponding backend services. All actions performed in Horizon are ultimately translated into API calls to the corresponding backend services.

#### 2.9 Keystone
Keystone is the identity service used by OpenStack for authentication (authN) and high-level authorization (authZ). It currently supports token-based authN and user-service authorization. it is similar to kerberos for authentication management.

#### 2.10 Magnum
Magnum is an OpenStack project which offers container orchestration engines for deploying and managing containers as first class resources in OpenStack. There are several different types of objects in the magnum system:
- Cluster: A collection of node objects where work is scheduled
- ClusterTemplate: An object stores template information about the cluster which is used to create new clusters consistently

#### 2.11 Sahara (Data Processing for Big Data)
The sahara project aims to provide users with a simple means to provision data processing frameworks (such as Apache Hadoop, Apache Spark and Apache Storm) on OpenStack. This is accomplished by specifying configuration parameters such as the framework version, cluster topology, node hardware details and more.

#### 2.12 Trove (DBaaS)
Trove is Database as a Service for OpenStack. It's designed to run entirely on OpenStack, with the goal of allowing users to quickly and easily utilize the features of a relational database without the burden of handling complex administrative tasks.

#### 2.13 Designate
OpenStack Designate provides DNS as a Service (DNSaaS) in OpenStack. It provides a standard, open API that can be used to program DNS. Designate is protected by and integrates with Keystone authentication authorization mechanisms like all OpenStack APIs. </br>
pools are used as discrete name servers. Private pools (internal sites) and public pools (external sites). pools are used to spread the load across name servers.

#### 2.14 Heat
Heat is an OpenStack component responsible for Orchestration. Its purpose is to deliver automation engine and optimize processes and it uses stacks. Heat receives commands through templates which are text files in yaml format. A template describes the entire infrastructure that you want to deploy. templates in Heat are known as HOT (Heat Orchestration Template). </br>
Template contain 4 components:
- Resources: Contain the objects that are created
- Properties: Specifics of the template such as the flavor
- Parameters: Properties of specific resources
- Output: what is passed back to the user.

#### 2.15 The Message Broker
It facilitate interprocess communication between services. it uses RabbitMQ, ZeroMQ, Qpid for facilitation. it allows messages to be sent between different cloud services, using authentication tokens. takes care of sending messages in an orderly way. time syncronization is important thing in this service.

#### mandatory backend Services
2 services are mandatoy in Openstack.
1. RabbitMQ
2. Database (depend on the service)
you can verify their status via `systemctl status` command for each. 

#### Ceilometer (Telemetry):
Ceilometer is an OpenStack service that provides cloud metrics. The data this service provides can be used for customer billing, resource usage analysis, and to send alerts. Reference: Ceilometer Documentation.

#### Ironic (Bare Metal Deployment)
Ironic is an OpenStack project which **provisions bare metal** (as opposed to virtual) machines. It may be used independently or as part of an OpenStack Cloud, and integrates with the OpenStack Identity (keystone), Compute (nova), Network (neutron), Image (glance) and Object (swift) services.

#### Oslo (Standardization)
provides a framework for defining new long-running services using the patterns established by other OpenStack applications. It also includes utilities long-running applications might need for working with SSL or WSGI, performing periodic operations, interacting with systemd, etc. Installation. Usage.


### RDO (RPM Distribution Openstack) Project
RDO is an effort to package upstream OpenStack, and make it useful for users of Red Hat Enterprise Linux and CentOS. RDO is a community of people using and deploying OpenStack on CentOS Stream and Red Hat Enterprise Linux. We have documentation to help get started, mailing lists where you can connect with other users, and community-supported packages of the most up-to-date OpenStack releases available for download.
[RDO-Project](https://www.rdoproject.org/contribute/onboarding/)


#### Redhat Openstack Related solutions Overview
- **Red Hat Openstack**: RH Openstack Distribution that are available in www.rdoproject.org
- **Red Hat OpenShift**: Platform as a Service (PaaS) soluttion that is using containers to deploy cloud solutions rapidly.
- **Red Hat CloudForms**: Red Hat CloudForms provides unified cloud management that enables organizations to rapidly transform their existing virtual infrastructures into highly scalable, private clouds as well as take advantage of public cloud resources.
- **Red Hat Cloud Infrastructure**: Red Hat Cloud Infrastructure helps you implement an open private cloud to deploy and efficiently manage traditional enterprise workloads and the new class of cloud-architected workloads


### Introduction to Packstack 
Packstack is a utility that uses Puppet modules to deploy various parts of OpenStack on multiple pre-installed servers over SSH automatically. **Currently only CentOS, Red Hat Enterprise Linux (RHEL) and compatible derivatives of both are supported.** </br>
packstatck uses answer files and puppet to deploy a state on the openstack nodes. the answer file is generated before deployment and contains essential configuration settings.</br>
puppet is used as the deployment solution to implement the state on the these machines.


### Ubuntu OpenStack Deployment Method
Openstack can be deployed on debian based system in our case Ubuntu in various forms.
- **Distribution integrated** from the ubuntu Server installation
- **Developer oriented** using devstack
- **Corporate deployment** using juju / Autopilot





