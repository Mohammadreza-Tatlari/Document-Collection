# Service Discovery For Linux

### Overview
Windows Service Discovery Template that collects all Services Available on Windows Hosts With a Pythons Script. Then, based on collected Data it Creates Item and Trigger for each services.



### Items:

#### Item Prototypes:
1. Windows Service Active
	: checks if the discovered service is active or not by returning binary

#### Trigger Prototype:
1. Service Not Active:
	- sends alert if service is not being active. it returns 1 for active and 0 for not active.


### Requirement:
1. The " windows-ServiceDiscovery.py " file which is a simple script that lists service should be placed in a directory that allows zabbix agent to run it based on User Parameters.

2. Python Packages should be installed on End Host OS.

3. Note that the Path of Python should be defined for UserParamter in order to allow Zabbix Agent to run the code. Otherwise, it can cause problem in output.


```sh
UserParameter=service.Windows,"C:\path-to-python\python.exe" "C:\zabbix-scripts\window-services.py"
#for example:
#UserParameter=service.discoveryWindows,"C:\Programs\Python\Python310\python.exe" "C:\zabbix-scripts\window-services.py"

UserParameter=service.isactivewindow[*], powershell -Command "if (Get-Service -Name " $1 " -ErrorAction SilentlyContinue) { if ((Get-Service -Name " $1 ").Status -eq 'Running') { 1 } else { 0 } } else { 0 }"
```



### Caution: 
> The Execution Code have some shortage for instance based on Name of Service it can be erring. for instance Service Names with space between them can cause faulty outcome