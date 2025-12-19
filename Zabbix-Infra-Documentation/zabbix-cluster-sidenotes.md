

--- 
### Tuning Practices for SNMPAgentPoller on Frontend in Item Creation
#### Instead of Discovery rule, a new walk item needs to be created.
For example:
instead of `cpu.discovery` use `cpu.walk`
instead of `discovery[{$SNMPVALUE}, 1.3.6.1.4.1.9.9.109.1.1.1.1.8]` use `walk[1.3.6.1.4.1.9.9.1.09.1.1.1.1.8]`

#### Discovery rule needs to be converted to dependent discovery rule
for example:
instead of `cpu.discovery` as a **SNMP agent** use `cpu.discovery` as **Dependent item** with a Master item of **SNMP walk**

- Use preprocessing to convert walk output to JSON on LLD rule </br>
in Hosts > Items > Discovery rule. when creating a Discovery rule check out preprocessing and use Parameters.

#### Convert item prototypes to dependent items which will take values from walk item
instead of Type:`SNMP agent` use Type:`Dependent item` and select Master item.

- use Preprocessing to extract values from the master item on the item prototype

#### use preprocessing to limit LLD rule execution time
in Discovery rule create > Preprocessing > add `Discard unchanged with heartbeat` and assign an interval of for instance `12h`



### Zabbix Service Parameters (Before changing Zabbix own Configuration Parameters)
Before Changes on Zabbix Parameters, Zabbix Service Params should be modified based on your needs:
`vim /usr/lib/systemd/system/zabbix-server.service` => service file on zabbix-server
`vim /usr/lib/systemd/system/zabbix-server.service` => service file on proxy-server(s)

the changeable parameters:
`LimitNOFile=100000`: number of files that zabbix can create
`TasksMax=32768`: the maximum number of tasks that may be created in the unit.


#### Asynchronous processes
- `SNMPAgentPoller - StartSNMPPollers`: Number of pre-forked instances of asynchronous SNMP pollers. Also see MaxConcurrentChecksPerPoller. </br>
- `AgentPoller - StartAgentPollers`:  Number of pre-forked instances of asynchronous Zabbix agent pollers. Also see MaxConcurrentChecksPerPoller. </br>
- `HTTPAgentPollers - StartHTTPAgentPollers`: Number of pre-forked instances of asynchronous HTTP agent pollers. </br>
- `Discover - StartDiscoverers`: Number of pre-started instances of discovery workers. </br>

#### `MaxConcurrentChecksPerPoller`
Maximum number of asynchronous checks that can be executed at once by each HTTP agent poller or agent poller. </br>
**change on this requires needs OS configurations**



### Proxy Tuning
this section is about all parameters and values solely related to proxy config.

### Proxy Memory buffer with `ProxyBufferMode` and its values:
`disk`: all data gets stored in DB on Disk
`memory`: All data gets stored in memory (RAM), No protection against data loss.
`hybrid` Recommended: Uses memory in most cases, Data loss protection using DB


### Proxy load balancing
Proxy groups managed by Zabbix server. Auto rebalancing of hosts. In case of issues, host gets automatically 
assigned to a working proxy.
it can be configured in Administration > Proxy groups > (creating Proxy Group) > and assigning other proxy servers to it.


### Proxy LLD by Zabbix server
#### Zabbix server health template
LLD of Proxies that are connected to the server. Creates Basic itmes and triggers, show various statistic from proxy. </br>
*Remember to retrieve the latest health templates after upgrading to a new major Zabbix version*


#### Configuring Update Intervals
Configuration updates are incremental
- Zabbix server reloads configuration
- Zabbix proxy reloads configuration 
- Active agent reloads configuration



### Zabbix Internal Process Tuning
#### Tuning Workers
Most worker usage needs to be between 40-60%, Zabbix server and proxy have almost the same set of workers.
Zabbix and Proxy Workers:
Alerter - Escalator - HTTP poller - History syncer - History poller - Timer - LLD worker - Java poller - Poller 

#### History syncers 
Writes data into the database, calcuates trigger, **1 History syncer can deal with ~1000NVPS**.

Causes of Error related to `Zabbix history Syncer processes more than 75% busy`:
- Data cannot be written to the db fast enough
- Lots of triggers to be calculated 
- Most often DB related 

**Fixes:** </br>
- Tune and check DB performance
- Check triggers
- Improve hardware (if all tuning and Workers are well adjusted)
- Increase history syncer amount ( 1 history syncer = 1000NVPS)


#### LLD Workers
Performs low-level discovery, **High impact on DB performance**, Only on Zabbix server, Usually, **best not to increase above the default amount**

Cause of Error Related to `Utilization of lld worker process is high`
- Frequent execution of low-level discovery rules
- Most often DB related

**Fixes:** </br>
- Tune and check DB performance
- Increase update interval for low-level discovery rules
- Increase “Discard unchanged with heartbeat” period for dependent low-level discovery rules
- Increase LLD workers **Every LLD worker causes huge load on DB**



#### Caches
Most cache usage should be between 40% and 60%, Zabbix server and proxy have almost the same set of caches:
- Value Cache
- Configuration cache
- Trend cache

#### Value Cache
Stores values for easier accessibility, Is used for trigger calculation, Is used for calculated items, Almost limitless, **Never should be Full** </br>

Cause of Error related to `More thant 95% used in the value cache` and `Zabbix value cache working in low memory mode`: </br>
- Lots of triggers
- Lots of functions that use forecasting
- Lots of calculated items

**Fixes:** </br>
- Increase ValueCacheSize (**Make sure there is enough RAM on the server**)
- Adjust forecast/trigger periods

#### Configuration Cache
Store Configuration, Almost limitless, **Never should be full, if it gets full, Zabbix Server/Proxy craches**

Cause of Error related to `More than 75% used in the configuration cache`:
- Lots of hosts, Items, Triggers

**Fixes:** </br>
Increase CacheSize (**Should be Enough RAM on Servers**)



### History and history index Cache

#### History Cache
Stores values after they are preprocessed, History syncer takes the values from this cache and writes them to the database, 2 GB Limit, **Never should be full and should be as emty as possible** </br>

#### History index Cache
indexes history cache, **1/4 size if history cache**

Cause of Error Related to `More than 75% used in the history cache` and `More than 75% used in the history index cache`: </br>
- Data cannot be written in the DB fast enough
- Most of the time issues arise together with history syncer

**Fixes:** </br>
- Tune and check DB performance
- Increase `HistoryCacheSize` and `HistoryIndexCacheSize` (**Make sure Enough RAM is on Server - it only applies if your DB is big**)


#### Tune Other Processes and cache
- Most process worker and cache usage should be maintained between 40% and 60%
- If the default settings are being used, it's acceptable for the usage to be lower


### Managers (Manager processes cannot be tuned!)
- High manager usage typically happens when worker usage grows
- Needs to be checked what is causing the issues - diaginfo, reading log files.

#### Queue
- Values that have not yet arrived, Fixable, has many reasons to appears 


#### Important Notes:
- Use built-in **health templates**
- Dashboards of server/proxy performance
- Monitor OS metrics of server/proxy using Zabbix agent
- Remember to update the templates when upgrading to next major release

#### Recommended Health Monitors and Values:
- Values processed per second
- Utilization of data collectors (for proxy/server)
- Cache size
- Value cache hits
- queue
- ...


#### Tune Frontend
Frontend can become slow and unresponsive over time and **issues can be caused by web server or the DB**. </br>

for Monitoring web-server performance: </br>
- enable debug mode (it can be done for whole page or individual widgets)
    - look for web server issues -`Total time` and Dtabase issues - `Total SQL time` in debug mode values.


#### Tune Frontend File (`/etc/php-fpm.d/`):
Web Server configuration can be changed in `/etc/php-fpm.d/zabbix.conf` or `/etc/nginx/conf.d/zabbix.conf`


#### triggers
- Huge amount of trigger changes in a short time period creates lots of events. Lots of events = load on DB. Regularly observe Reports and Top 100 triggers or dashboard widget

#### Tuning Triggers
- Use proper functions
- Adjust time intervals
- Alert fatigue
- LLD overrides allow to not discover triggers based on regexp
- Recovery expression
- Limit nodata() usage


#### Tuning Templates
- Default templates are good, however, require attention
- Switch old SNMP templates to use asynchronous checks
- Think about update interval
