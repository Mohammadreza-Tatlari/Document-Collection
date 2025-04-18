# copyright 2020,2021,2022 Sean Bradley https://sbcode.net/zabbix/
import sys
import os
import json

SERVICES = os.popen('systemctl list-unit-files').read()

ILLEGAL_CHARS = ["\\", "'", "\"", "`", "*", "?", "[", "]", "{", "}", "~", "$", "!", "&", ";", "(", ")", "<", ">", "|", "#", "@", "0x0a"]

DISCOVERY_LIST = []

LINES = SERVICES.splitlines()
for l in LINES:
    service_unit = l.split(".service")
    if len(service_unit) == 2:
        if not [ele for ele in ILLEGAL_CHARS if(ele in service_unit[0])]:
            status = service_unit[1].split()
            if len(status) == 1:
                if (status[0] == "enabled" or status[0] == "generated"):
                    DISCOVERY_LIST.append({"{#SERVICE}": service_unit[0]})
            else:
                if (status[0] == "enabled" or status[0] == "generated") and status[1] == "enabled":
                    DISCOVERY_LIST.append({"{#SERVICE}": service_unit[0]})
