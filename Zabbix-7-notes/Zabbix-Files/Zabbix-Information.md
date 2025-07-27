# Zabbix for Large Scale Datacenter .

### Brain Storm:
0. Containerize most of services
01. gather information related to best implementation for data center that has SOC, Storage and Network Devices.
02. This Project should be related to Infrastructure Need of Zabbix.
03. It should contain HA and should be up by container.
04. who do we need for this project, build up your team.
05. provide a Road Map and Schema for it
06. stress testing the product.
07. security and its hardening

#### Links 
[justinc Response related to its 2012 experience on a medium size project](https://www.zabbix.com/forum/zabbix-for-large-environments/25682-zabbix-for-large-environment-setups) <br>
[Mocho experience in 2019 realted to a project with 150k nodes](https://www.zabbix.com/forum/zabbix-for-large-environments/377127-large-scale-setup-documentation) <br>
[Jacksmithh question related to zabbix implementation](https://www.zabbix.com/forum/zabbix-troubleshooting-and-problems/483470-zabbix-configuration-for-large-scale-network-monitoring) <br>


### Data Gathering:
1. PostgreSQL (should be separated)
    - Database implementations.
        - what if data increase and we need more postgresql services (ocntainers)? 
        - how does it should keep the data (hot, cold, freeze)
        - You are going to need some Fast Storage for your DB
        - You are going to want as much memory in your DB as possible
2. Applicaton
3. Nginx (Frontend works in same box as application)
4. proxy servers (should separate networks to different isolated sections) **HAProxies**
5. **grafana** (should work on separated platform)
6. nested templating
7. will it monitor **services**? will it be used for docker **containers**, and **cloud services**? make space for future implementations.
8. what kind of **protocols** should be used for different **devices**, servers, or **scenarios** or even during a **certain period** <br>




### DBMS (DataBase Management System)
For DBMS, Postgresql is select due to its feature-riched functionality and Concorruncy. also Managing HA for Database. However Postgresql request more resource than mysql. <br>
note that Zabbix database replication involves creating replicas of your Zabbix database to improve data accessibility, fault tolerance, and reliability which can be achieved via postgresql.

what is used of [influxdb-zabbix](https://github.com/zensqlmonitor/influxdb-zabbix) <br>
how to to use [Postgresql HA](https://www.postgresql.org/docs/current/high-availability.html)
#### Postgresql for Concurrency
eventhough Postgresql consume a little bit of more resource, more than Mysql it has a concurrency feature which helps to improve performance on processing data. <br>
however this benefit comes with cost that are discussed in links belew: <br>
[why Postgresql instead of Mysql](https://www.bytebase.com/blog/postgres-vs-mysql/) <br>
[downside of Postgresql](https://www.cs.cmu.edu/~pavlo/blog/2023/04/the-part-of-postgresql-we-hate-the-most.html)

#### Database Partitioning for hot and cold storage
Paritioning Database Table Before Zabbix Initiation. (housekeeper bottleneck)
partition off the history_xxxx tables onto some PCIe SSD 
    - Parition History tables by day
    - Parition History tables by month
- Table Spaces: You'll create PostgreSQL tablespaces that are specifically associated with the mount points of your SSD and HDD volumes. <br>
Create a tablespace for your SSD (e.g., hot_storage) pointing to the SSD mount path. <br>
Create another tablespace for your HDD (e.g., cold_storage) pointing to the HDD mount path. <br>

- **PgBouncer or Pgpool-II** for remote database
#### Database Optimization
I'm looking at writing some very basic code to either pull (read off slave with modifications to [influxdb-zabbix](https://github.com/zensqlmonitor/influxdb-zabbix) or push data (module) to Kafka or InfluxDB directly for the Trend/Historical keeping because of the sheer volume of data.

#### load balancing the DBMS Services
 (not yet discussed)


### WORKING WITH DOCKER IN ZABBIX
how to implement each service via Container and how to sync the process.
- be able to handle failovers of the container (restartable all the time)

Containers: <br>
- Zabbix Server (PostgreSQL)
- Zabbix Proxy (SQLite3)
- Zabbix Frontend (Apache PostgreSQL)
- Zabbix Agent2 (TLS encryption)
- Zabbix Java (Gateway)
- Zabbix snmptraps: The image is used to receive SNMP traps, store them to a log file and provide access to Zabbix to collected SNMP trap messsages.

- Zabbix Web Service "Need more research for its usecase"




### HA (Native High Availablity)
The HA in zabbix can be acheived by Active and Standby Nodes for hand over situations. <br>
[Setup for High Availability in Zabbix](https://www.zabbix.com/documentation/current/en/manual/concepts/server/ha#:~:text=Only%20one%20node%20can%20be,compatible%20across%20minor%20Zabbix%20versions.)





[Forum](https://www.zabbix.com/forum/zabbix-for-large-environments/25682-zabbix-for-large-environment-setups)
[Zabbix Installtion](https://www.zabbix.com/documentation/current/en/manual/installation/containers)
[HA ZABBIX](https://www.zabbix.com/documentation/current/en/manual/concepts/server/ha#implementation-details)
[Solutins](https://www.zabbix.com/solutions)
[Tempates](https://www.zabbix.com/integrations?cat=official_templates)