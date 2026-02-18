
---
## How to remove an Active Router in Openstack 

1. Identify its port:
- `openstack router list`
- `openstack port list`
- `openstack port show <ID> -c device_owner`
- `openstack port show <ID>`

2. remove its subnet id (if it is active)
- `openstack router remove subnet <router-name> <subnet-id>`

3. finally remove the router
- `openstack router delete <router-name>`




---
## Fixing 503 Bad Gateway Error in Horizon Web UI.
before processing through troubleshooting we need to first check the logs.
1. check out the web browser with F12 Inspect
2. check horizon uWSGI django logs:
- `tail -f /var/log/kolla/horizon/horizon-uwsgi.log`
  - if you are receiving the `OSError [Errno 24]` it means that we are getting Too many open file error and it is related to OS limits.
3. if it is file limit error then change the `ulimit` variables as follow on OS level (it should be more than `1024`):
- `ulimit -n 5000` for example



