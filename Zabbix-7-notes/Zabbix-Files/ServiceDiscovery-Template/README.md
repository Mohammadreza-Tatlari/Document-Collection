
# Service Discovery For Linux

## Overview

this template find and check status of all services that are running on Linux Hosts.

### Items:

#### Item Prototypes:
1. Is Service Active
	: checks if the discovered service is active or not by returning binary

2. Service Active Time:
	: receives the active time of service.

> note: services are created with enabled uncheck. so services will be discovered but will not be enabled.

• Trigger Prototypes:
1. Service Not Active:
	- sends disaster alert if service is not being active

2. Service Restarted
	- Sends warning whether the enabled item is restarted


Requirement:
1. The service_discovery.py file which is a simple script that lists service should be places in a directory that allow zabbix user to run it.

2. three UserParameters need to be added to zabbix agent (active) configuration file which are:

```sh
UserParameter=service.discovery, python3 /home/zabbix/service_discovery.py 
UserParameter=service.isactive[*],systemctl is-active --quiet '$1' && echo 1 || echo 0
UserParameter=service.activatedtime[*], systemctl show '$1' --property=ActiveEnterTimestampMonotonic | cut -d= -f2
```