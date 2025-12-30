# Ceph Topics Simplified 

## Ceph Object Gateway (RGW) - [IBM Ceph Object Gateway](https://www.ibm.com/docs/en/storage-ceph/7.1.0?topic=ceph-object-gateway) - [Wiki Object Storage](https://en.wikipedia.org/wiki/Object_storage)

#### Original Text: </br>

> #### Ceph Object Gateway supports three interfaces:
> S3-compatibility
> Provides object storage functionality with an interface that is compatible with a large subset of the Amazon S3 RESTful API.
> Swift-compatibility
> Provides object storage functionality with an interface that is compatible with a large subset of the OpenStack Swift API.
> The Ceph Object Gateway is a service interacting with a Ceph storage cluster. Since it provides interfaces compatible with OpenStack Swift and Amazon S3, the Ceph Object Gateway has its own user management system. Ceph Object Gateway can store data in the same Ceph storage cluster used to store data from Ceph Block Device clients; however, it would involve separate pools and likely a different CRUSH hierarchy. The S3 and Swift APIs share a common namespace, so you can write data with one API and retrieve it with the other.
>
> #### Administrative API
> Provides an administrative interface for managing the Ceph Object Gateways.
> Administrative API requests are done on a URI that starts with the admin resource end point. Authorization for the administrative API mimics the S3 authorization convention. Some operations require the user to have special administrative capabilities. The response type can be either XML or JSON by specifying the format option in the request, but defaults to the JSON format. </br>



### Simplified:
To simplify Ceph RGW (RADOS Gateway), it helps to think of it as a **translator**. 

Ceph itself speaks a "language" called RADOS, which most applications don't understand. The RGW sits in front of the storage cluster and translates common web languages (S3 and Swift) into RADOS so the storage can process them.


### 1. The Three Interfaces (The Translators)
The RGW offers three main ways to talk to it:

* **S3-Compatibility:** This is the most popular. If you have an app designed to work with Amazon S3, you can usually point it at Ceph RGW instead, and it will work without changing your code.
* **Swift-Compatibility:** This is for the OpenStack ecosystem. It works just like S3 but uses the "Swift" style of naming and organizing files.
* **Administrative API:** This isn't for storing files; it’s for **managing the system**. You use this to create new users, check usage quotas, or manage buckets. Think of it as the "Control Panel" interface.





### 2. Key Concepts Simplified

#### **User Management**
Because the RGW mimics S3 and Swift, it can't use the standard Ceph "cephx" authentication (which is for servers and disks). Instead, it has its own internal "phonebook" of users. Each user gets an **Access Key** and a **Secret Key**, exactly like they would on Amazon AWS.

#### **The "Common Namespace"**
This is a powerful feature. Because S3 and Swift are just two different ways to talk to the same storage, they share the same data. 
* **Example:** You can upload a photo using the S3 interface and download that exact same photo using the Swift interface. They are looking at the same "bucket" or "container."

#### **Data Isolation (Pools & CRUSH)**
The text mentions "separate pools" and "different CRUSH hierarchies." 
* **Pools:** Even if you use Ceph for virtual hard drives (RBD) and object storage (RGW) on the same hardware, Ceph keeps them in separate "folders" (pools) so they don't interfere with each other.
* **CRUSH Hierarchy:** You might want your Object storage to live on slow, cheap SATA drives, while your Block storage (for databases) lives on fast NVMe drives. A different CRUSH hierarchy allows you to physically separate where the data actually lands on the disks.


### 3. Critical Engagement: Assumptions & Potential Issues
While the RGW is versatile, there are a few nuances that the text glosses over:

* **The "Compatibility" Trap:** The text says "compatible with a large subset." This is a polite way of saying **it is not 100% compatible**. If your application relies on specific, advanced AWS features (like certain S3 Object Lock behaviors or specific IAM policy granularities), the RGW might fail. Never assume an S3-app will work perfectly without testing the specific API calls first.
* **Performance Overhead:** Because the RGW is a "translator" (an extra layer), it introduces latency. Direct access to RADOS is faster. If your application needs absolute maximum speed, the RGW might be a bottleneck unless you scale it horizontally (running multiple RGW instances).
* **Shared Namespace Risks:** While writing with S3 and reading with Swift is possible, it can lead to metadata headaches. S3 and Swift handle things like "metadata headers" and "access control lists (ACLs)" differently. If you mix them frequently, you may find that permissions set in S3 don't translate perfectly to Swift's permission model.



---

## Day 0, Day 1 and Day 2 Methodology

### Original Text: </br>
> This terminology is common in IT and DevOps, but it’s often used loosely. To understand it in the context of Ceph, it helps to see it as a **project timeline** rather than a list of software features.

### Simplified:s
Think of it like building a house: **Day 0** is the blueprint, **Day 1** is the construction, and **Day 2** is the interior design and maintenance.

### The Breakdown

| Phase | Action | In the Context of Ceph RGW |
| :--- | :--- | :--- |
| **Day Zero** | **Planning** | Deciding how many servers you need, what kind of disks (SSD vs. HDD) to buy, and mapping out your network topology. |
| **Day One** | **Deployment** | Running the installation scripts (like `cephadm`), installing the RGW packages, and getting the "daemons" running. |
| **Day Two** | **Operations** | Creating users, setting storage quotas, fine-tuning performance, and handling hardware failures. |




### Critical Perspective: Why this model can be misleading

While this methodology provides a "logical progression," it has some inherent flaws and biases that you should keep in mind as you learn:

* **The "Clean Cut" Fallacy:** In reality, the lines are blurred. You will often find yourself back in "Day 0" (re-planning your architecture) because of something you discovered during "Day 2" (actual usage). The model implies a linear path, but Ceph management is usually **cyclical**.
* **The Underestimation of Day Two:** Most documentation focuses heavily on Day 0 and Day 1 because they are exciting and involve "getting it working." However, **90% of a system's life is Day 2**. In Ceph, "advanced configuration" isn't just a one-time setup; it involves constant monitoring of data rebalancing and placement groups.
* **Automation Bias:** Modern tools (like Kubernetes or Cephadm) try to merge Day 1 and Day 2. They "install" and "configure" simultaneously. Relying too heavily on a manual "Day One, then Day Two" mindset can sometimes prevent you from using automation tools that handle both at once.

### Summary
If you are reading a manual organized this way, just remember:
* **Day 0** = Research & Design.
* **Day 1** = Installation.
* **Day 2** = Everything else (The "Forever" phase).











