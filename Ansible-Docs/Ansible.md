Servers Being Used:
etcd-mgt-srv1 172.24.24.11
etcd-mgt-srv2 172.24.24.12
etcd-mgt-srv3 172.24.24.13
Jumper: sadouq 172.24.24.53 

## What is Ansible
Ansible is an open source, command-line IT automation software application written in **Python**. It can configure systems, deploy software, and orchestrate advanced workflows to support application deployment, system updates, and more. in nut shell, it is used to provision Servers. it does this provisioning via **Ansible Control Host**. it applies changes to servers via for example SSH Connection to Other Servers. </br>
there is no single format of doing ansible but there are best practices which are used for configuring servers.

### Version Control System and Ansible
By keeping your Ansible code in a git repository you will be able to track changes to the code. If you're working on a project with little collaboration it is easy to fall into the temptation of committing all your changes straight into the master branch. it also helps you to revise your code before applying to all servers and prevent unstable changes to servers </br>


## Create SSH-Key and SSH Connection for ansible
we are going to use SSH-Key Based Connection From our ansible machines to Servers. for doing that we first need to generate a Unique SSH for our Ansible Code and Then Copy its Public Key to Target machines. this way we can stablish passwordless Connection to Servers via SSH. </br>

the steps for password-less connection: </br>
1. Generate a SSH Key for "ansible"
`ssh-keygen -t ed25519 -C "ansible"` => it will prompt and ask you for location and name of file where you want to keep the Private and Public Key. and will save the generated key there.
- for passphrase you can empty the passphrase for the beginning step. but **you have to keep the keys very secure.**

2. copy the SSH Public key to servers:
`ssh-copy-id -i ./location-of-publickey/acd nsible.pub <IP_Address_of_Target_Machine>` => it will ask you for the passphrase but not the old passphrase, it is prompting for the newly generated key 


3. evoke ssh-agent to store password (optional)
    1. `eval $(ssh-agent)` => this command will start `ssh-agent` service to run in the background with its defined IP and then it will save passwords for each connection </br>
    2. `ssh-add` => it will add the ssh private key to ssh-agent
    3. `alias ssha='eval $(ssh-agent) && ssh-add'` => it will simple create alias with the name `ssha` and each time you type `ssha` it will do the 2 previous steps. </br> 
        1. you can add the `alias` command to your `.bashrcs` file in anywhere and you can have it even after reboot 


## Core Git Concepts for Ansible
**why should we use git for ansbile?**
When teams start with Ansible, they often store playbooks locally on a control node. This creates several critical vulnerabilities:
- Single Point of Failure: If the control node crashes, years of automation work vanishes
- No Change Tracking: Who changed what, when, and why? Without version control, you’re blind
- Collaboration Barriers: Team members can’t safely  work on the same automation simultaneously
- No Rollback Capability: Mistakes become disasters when you can’t revert changes
- Knowledge Silos: Automation expertise stays locked in individual workstations

### install git on your Ansible Host and also create a Repository for it.
for install git simply use: </br>
`sudo apt install git` and check its installation with `git --version`

for repository you can both use **Gitlab** or **Github** to be used for Repository (It is out of scope of this Document but check out these links [Hello-Github](https://docs.github.com/en/get-started/start-your-journey/hello-world) & [git-tutorial](https://git-scm.com/docs/gittutorial) )


### Add Github/Gitlab SSH key to your Ansible Host
1. you need to copy your generated **SSH Public key** to your github Repository it can be achieved in "github > Setting > SSH and GPG key > "New SSH Key" "

2. you need to configure global git configs on your Host machines:
`git config --global user.name "your git name"` => note it can be any name or it can be **your exact github account name**
`git config --global user.mail "youremail@email.com"` => the email that is used for your repository 

`git ~/.gitconfig` => verify your name and email via this command 



## Installing Ansible 
to install ansible packages on Ubuntu you can follow up on [Ansible On Ubuntu](git@github.com:Mohammadreza-Tatlari/Ansible-PracticeRepo.git).
1. `sudo apt update` => update your packages
2. `sudo apt intall ansible` => install ansible packages


### Ansible Inventory
**What is an Ansible inventory file?** </br>
An Ansible inventory is a collection of managed hosts we want to manage with Ansible for various automation and configuration management tasks. Typically, when starting with Ansible, we define a static list of hosts known as the inventory.


#### Building Inventory 
to create your 'inventory', it is recommended to create it in your VCS repository but its optional. </br>
in your directory create a `inventory` file and place all your IP address of your control Nodes: </br>
`vim inventory`:
```
172.24.24.11
172.24.24.12
172.24.24.13
....
```


### First Connection with Inventory host
to connect ansible to host and provision the addresses defined in inventory file we can do a simple check via: </br>

`ansible all --key-file ~/.ssh/ansible -i inventory -m ping` => it will use the SSH private key file and then we define our inventory via `-i` command and then use ping module via `-m`. it makes us sure that things are working properly. it should return a similar result: </br>

```
172.24.24.12 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
172.24.24.11 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
172.24.24.13 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```


### Create Ansible Config File
The ansible-config utility allows users to see all the configuration settings available, their defaults, how to set them and where their current value comes from. Ansible supports several sources for configuring its behavior, including an ini file named `ansible.cfg`, **environment variables**, **command-line options**, **playbook** keywords, and variables. for more info check this [Document](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings)

in your directory, create a `ansible.cfg` file and add the following scripts:

`vim ansible.cfg`:

```ini
[defaults]
inventory = ./inventory #the location of inventory file
private_key = ~/.ssh/ansible # the location of private ssh key

```

then in the same directory where `ansible.cfg` is present do the following command: </br>
`ansible all -m ping`

**Note**: 
> the `ansible.cfg` file will override the configuration in the `/etc/ansible/config.cfg`.



### Ansible ToolKits
- Listing all Hosts that are in Inventory: </br>
`ansible all --list-host`

- Listing all Information from the hosts (it pulls information from host)
`ansible all -m gather_facts`
`ansible all -m gather_facts --limit 172.24.24.11` => limit the data gathering to specific host



### Writing Playbook
in ansible, palybooks are written in `.yaml` format. in this section we are going to write a simple playbook that will install apache2 packages on all hosts.

1. `vim apache2_installer.yaml`:

``` yaml
---
- hosts: all #apply it to all hosts in inventory
  become: true
  tasks:

  - name: updating index of apt 
    apt: 
      update_cache: yes
  - name: apache2 installer on Ubuntu Servers #name of the task
    apt: #defined package 
      name: apache2 
```

2. to run our playbook we use `ansible-playbook` util which is installed besides our ansible packages: </br>
`ansible-playbook --ask-become-pass apache2_installer.yaml` => it takes time because the ansible will go through checking the packages and verifying installation and so on but overall the result should be similar as following:

```s
PLAY [all] *******************************************************************************************************************************

TASK [Gathering Facts] *******************************************************************************************************************
ok: [172.24.24.13]
ok: [172.24.24.12]
ok: [172.24.24.11]

TASK [apache2 installer on Ubuntu Servers] ***********************************************************************************************
changed: [172.24.24.13]
changed: [172.24.24.11]
changed: [172.24.24.12]

PLAY RECAP *******************************************************************************************************************************
172.24.24.11               : ok=2    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
172.24.24.12               : ok=2    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
172.24.24.13               : ok=2    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

**NOTE:** the `--ask-become-pass` is used to pass password for ssh connection

**the playbook can be enriched as following:** </br>

```yaml
---

- hosts: all
  become: true
  tasks:

  - name: updating packages
   apt: 
     apt-cached: yes

  - name: installing apache2 packages
   apt:
     name: apache2
     state: latest

  - name: install php libraries
   apt:
     name: libapache2-mod-php
     state: latest

```


**Removing a Packages from Ubuntu**: to remove a packages, change the `status` to `absent`. 
``` yaml
---
- hosts: all
  become: true
  tasks:
  - name: removing apache2 packages
   apt:
     name: apache2
     state: absent
```


### When Condition in Ansible
The task will run only if the condition is true. If it is false, the task will be skipped to ensure no misconfigurations with environments occur will take place. 
for instance: <br>
we are going to add a condition that if the distro is Ubuntu or debain playbook will use `apt` package and otherwise it will skip and apply the relative task

```yaml
- hosts: all
  become: true
  tasks:

  - name: update apt index
    apt:
      update_cache: yes
    when: ansible_distribution in ["Debian", "Ubuntu"] #using ansible_distribution which is an ansible built in tool for checking distros

  - name: install apache2 on Ubuntu Servers
    apt:
      name: apache2
      state: latest
    when: ansible_distribution == "Ubuntu" and ansible_distribution == "Debian" #or we can use the `==` for checking condition this condition can be created by `ansible all -m gather_facts`
 
```

we can use ansible gather_fact module and grep on the distribution data and based on that create `when` condition:
1. `ansible all -m gather_facts --limit 172.24.24.11 | grep ansible_distribution` => it will pull data from the targeted file

2. `vim playbook.yaml` edit the play book yaml and create the `when` condition 

```yaml
---
- hosts: all
  become: true
  tasks:

# installation for Debain and Ubuntu
  - name: update apt index
    apt:
      update_cache: yes
    when: ansible_distribution in ["Debian", "Ubuntu"] 

  - name: install apache2 on Ubuntu Servers
    apt:
      name: apache2
      state: latest
    when: ansible_distribution in ["Debian", "Ubuntu"]

# Installation on CentOs
  - name: update dnf index
    dnf:
      update_cache: yes
    when: ansible_distribution in ["CentOS"] 

  - name: install apache2 on Ubuntu Servers
    apt:
      name: httpd
      state: latest
    when: ansible_distribution in ["CentOS"] 
    
```



### Optimizing the Task 
in previous sections we have learn how to install packages in different task but we can do clean up and write more effecient code. in the following we are going to write a playbook but with some changes

**Optimiation Version 1**
```yaml
---
- hosts: all
  become: true
  tasks:

  - name: installing apache2 and php packages packages
   apt:
     name:          # in this section we are installing two different packages in a single task
      - apache2
      - libapache2-mod-php
     state: latest
     update_cached: yes # it will work as the apt update option 
```

**Optimiation Version 2 not the absolute solution**
we can use "variables" and then defined those variables in "inventory" file. thus we don't need to use `when` condition for clarifying OS. we will use [package - Generic OS package Manager](https://docs.ansible.com/ansible/2.9/modules/package_module.html) module as well in this section

`playbook.yaml`:
```yaml
---
- hosts: all
  become: true
  tasks:

  - name: installing apache and php
    package: # it is an ansible module that use the exact package manager for the target OS
     name:          # in this section we are installing two different packages in a single task
      - "{{ apache_package }}"
      - "{{ php_package }}"
     state: latest
     update_cache: yes # it will work as the apt update option 
```

`inventory`:
```
172.24.24.11 apache_package=apache2 php_package=libapache2-mod-php
172.24.24.12 apache_package=apache2 php_package=libapache2-mod-php
172.24.24.13 apache_package=httpd php_package=php                   #for example if it is CentOS
```


### Targeting Specific Nodes

#### Creating Groups in Inventory
we can create group for different hosts in `inventory` file by putting their name into bracket ([]) similar as following:
```ini
[db_servers]
172.24.24.11
172.24.24.12

[web_servers]
172.24.24.13
```

``` yaml
---
- hosts: all
  become: true
  tasks:
    - name: Install Update (CentOS)
      dnf:
        update_only: yes
        update_cache: yes
      when: ansible_distribution == "CentOS"

    - name: Install Update (Ubuntu)
      apt:
        update_cache: yes
      when: ansible_distribution == "Ubuntu"

- hosts: web_servers
  become: true
  tasks:
    - name: Install apache and php for Ubuntu Web Servers
      apt:
        name:
          - apache2
          - libapache2-mod-php
        state: latest
        update_cache: yes
      when: ansible_distribution == "Ubuntu"

    - name: Install apache and php for CentOS Web Servers
      dnf:
        name:
          - httpd
          - php
        state: latest
        update_cache: yes
      when: ansible_distribution == "CentOS"
```


### YAML Check File
for reducing syntax error, simply use [yamlchecker](https://yamlchecker.com/).</br>

**NOTE:**:
> The `.yaml` playbook file should not have empty space in the end


#### pre_task
Ansible lets you run tasks before or after the main tasks (defined in `tasks:`) or roles (defined in `roles:`—we'll get to roles later) using `pre_tasks` and `post_tasks`, respectively. you can check the roles in [here](https://docs.ansible.com/ansible/latest/reference_appendices/glossary.html#term-Roles).


### Tags  
Tags are metadata that you can attach to the tasks in an Ansible playbook. They allow you to selectively target certain tasks at runtime, telling Ansible to run (or not run) certain tasks.

example of tags in `playbook.yaml` file:

```yaml
---
- hosts: all
  become: true
  tasks:
    - name: Install Update (CentOS)
      tags: always #always means that it will run in all filters
      dnf:
        update_only: yes
        update_cache: yes
      when: ansible_distribution == "CentOS"

    - name: Install Update (Ubuntu)
      tags: always
      apt:
        update_cache: yes
      when: ansible_distribution == "Ubuntu"

- hosts: web_servers
  become: true
  tasks:
    - name: Install apache and php for Ubuntu Web Servers
      tags: ubuntu,apache2,apache # we can use multiple tags for a single task
      apt:
        name:
          - apache2
          - libapache2-mod-php
        state: latest
        update_cache: yes
      when: ansible_distribution == "Ubuntu"

    - name: Install apache and php for CentOS Web Servers
      tags: centos,apache,php
      dnf:
        name:
          - httpd
          - php
        state: latest
        update_cache: yes
      when: ansible_distribution == "CentOS"
```


- to list all tags present in playbook: </br>
`ansible-playbook --list-tags playbook.yaml`

- for running only specific tags in playbook: </br>
`ansible-playbook --tags ubuntu --ask-become-pass playbook.yaml`



### Sending Files to Control Nodes
The [ansible.builtin.copy](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html#ansible-collections-ansible-builtin-copy-module) module copies a file or a directory structure from the local or remote machine to a location on the remote machine. File system meta-information (permissions, ownership, etc.) may be set, even when the file or directory already exists on the target system. Some meta-information may be copied on request.

example: </br>
we can create a simple `.html` file and send that to the control nodes via `playbook`:

```yaml
---
- hosts: web_servers
  become: true
  tasks:
   - name: Sending HTML file to Web Servers
     tags: webserver,apache2,httpd
      copy:
        src: ./index.html
        dest: /var/www/html
        owner: root
        group: root
        mode: 0644
```



### Sending File from Remote source to control nodes with `remote_src`
`remote_src` Influence whether src needs to be transferred or already is present remotely. and we can use an external source to send data to control nodes.

for example:
```yaml
---
- hosts: webserver
  become: true
  tasks:
  - name: install unzip
    package:
      name: unzip

  - name: install terraform
    unarchive:
      src: https://releases.hashicorp.com/terraform/1.13.4/terraform_1.13.4_linux_amd64.zip
      dest: /tmp
      remote_src: yes
      mode: 0755
      owner: root
      group: root
```



### Managing Services with ansible
we can make changes on services with ansible playbook. for instance changing the status of a httpd after being installed on CentOS, because httpd will not be started automatically after being installed on CentOS

for example:
```yaml
---
- hosts: web_servers
  become:
  tasks:
  - name: install apache and php on CentOS server
    tags: apache,centos,httpd
    dnf:
      name:
        - httpd
        - php
      state: latest
    when: ansible_distribution == "CentOS"

  - name: start httpd (CentOS)
    tags: apache, centOS, httpd
    service:
      name: httpd
      state: started
      enabled: yes #sets its state to enabled
    when: ansible_distribution == "CentOS"  
```

run the playbook via: </br>
`ansible-playbook --ask-become-pass playbook.yaml`


### changing service configuration file using `lineinfile` and `register`:
#### `lineinfile`
This module ensures a particular line is in a file, or replace an existing line using a back-referenced regular expression. This is primarily useful when you want to change a single line in a file only. </br>

#### `register`
You can create a variable from the output of an Ansible task with the task keyword `register`. You can use the registered variable in any later task in your play. note that should not use similar variable for different tasks.

example:
```yaml
---
- hosts: web_servers
  become:
  tasks:
  - name: install apache and php on CentOS server
    tags: apache,centos,httpd
    dnf:
      name:
        - httpd
        - php
      state: latest
    when: ansible_distribution == "CentOS"

  - name: start httpd (CentOS)
    tags: apache, centOS, httpd
    service:
      name: httpd
      state: started
      enabled: yes #sets its state to enabled
    when: ansible_distribution == "CentOS"

  - name: change e-mail address for admin
    tags: apache,centos,httpd
    lineinfile:                             #using lineinfile with path of the file, line of the script and the replacing line. 
      path: /etc/httpd/conf/httpd.conf
      regexp: '^ServerAdmin'                # regular expression is a very powerful util so we don't need to look for number of line
      line: ServerAdmin mohammadreza@email.com
    when: ansible_distribution == "CentOS"
    register: httpd                         # seving the result of task into a variable called "httpd"

  - name: restart httpd (CentOS)
    tags: apache,httpd,centos
    service:
      name: httpd
      state: restarted
    when: httpd.changed                     # using the register variable to only restart service if httpd is changed. 
```

run the play book: </br>
`ansible-playbook --ask-become-pass playbook.yaml`

check out the configuration file in control node:
`cat /etc/httpd/conf/httpd.conf | grep ServerAdmin`



### Adding Users and Boots trapping

#### [user](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/user_module.html#ansible-builtin-user-module-manage-user-accounts) module
To add a user in Ansible, you use the `user` module within a `playbook` or ad-hoc command. The user module manages user accounts on target systems. Depending on the state parameter, it can create, modify, or remove users. You can also set options like home directory, shell, UID, and encrypted passwords.

#### [authorized_key](https://docs.ansible.com/ansible/2.9/modules/authorized_key_module.html#authorized-key-adds-or-removes-an-ssh-authorized-key) module
Adds or removes SSH authorized keys for particular user accounts.

for example, we are going to add a user with name simone to our `web_servers` hosts and also add that user to sudoer with SSH key to connect remotely:
create a `sudoer_simon` file and add then set permission to it (**NOTE: there should not be a syntax error!**).</br>

`sudoer_simon`:
```ini
simone ALL=(ALL) NOPASSWD: ALL
```

`playbook.yaml`:
```yaml
---
- hosts: web_servers
  become: true
  tasks:
    - name: adding simone user 
      tags: always
      user:
        name: simone
        group: root

    - name: add ssh key for simone
      tags: always
      authorized_key:
        user: simone
        key: "ssh-public string comes here"     # example: cat ~/.ssh/ansible.pub

    - name: add sudeors file for simone
      tags: always
      copy:
        src: sudoer_simone      # file that was created to add permissions
        dest: /etc/sudoers.d/simone
        owner: root
        group: root
        mode: 0440
```

run the script via: </br>
`ansible-playbook --ask-become-pass playbook.yaml`

- check out `/etc/shadow` file in control nodes to see if `simone` user is added. </br>
- check authorized key on control hosts in simone's `.ssh/authorized_keys`. </br>
- ssh to the node hosts via ansible private key to verify the ssh connection: </br> 
`ssh -i ~/.ssh/ansible simone@172.24.24.13`



### passing password with `remote_user` in `ansible.cfg`
in `ansible.cfg`, by using `remote_user` we set the login user for the target machines. When blank is uses, the connection plugins the default. normally the user currently executing Ansible. </br>
for example:
```ini
[defaults]
inventory = ./inventory
private_key = ~/.ssh/ansible
remote_user = mohammadreza      # add remote_user 
```

after the change we can simply run ansible play book without `--ask-become-pass`: </br>
`ansible-playbook playbook.yaml`



### Roles in Ansible
Roles let you automatically load related vars, files, tasks, handlers, and other Ansible artifacts based on a known file structure. After you group your content into roles, you can easily reuse them and share them with other users. [Role structure](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_reuse_roles.html#roles).

in this scenario we are going to associate multiple roles into our playbook and then create directory and `main.yaml` file based on each role. </br>

1. Create a roles directory
 `mkdir roles`

2. Create a directory for each role you wish to add:
```sh
cd roles
mkdir base
mkdir db_servers
mkdir file_servers
mkdir web_servers
mkdir workstations
```

3. Inside each role directory, create a tasks directory and relative `main` and folder files
```sh
cd <role_name>
mkdir tasks
```

- `based/main.yaml`:
```yaml
- name: add ssh key for simone
  authorized_key:
    user: simone
    key: "ssh-ed25519- private key"
```

- `db_servers/main.yaml`
```yaml
- name: install mariadb server package (CentOS)
   tags: centos,db,mariadb
   dnf:
     name: mariadb
     state: latest
   when: ansible_distribution == "CentOS"
 
 - name: install mariadb server
   tags: db,mariadb,ubuntu
   apt:
     name: mariadb-server
     state: latest
   when: ansible_distribution == "Ubuntu"
```

- `file_servers/main.yaml`
```yaml
- name: install samba package
  tags: samba
  package:
    name: samba
    state: latest
```

- `workstations/main.yaml`
```yaml
- name: install unzip
  package:
    name: unzip

- name: install terraform
  unarchive:
    src: https://releases.hashicorp.com/terraform/0.12.28/terraform_0.12.28_linux_amd64.zip
    dest: /usr/local/bin
    remote_src: yes
    mode: 0755
    owner: root
    group: root
```

- `web_server/main.yaml`
```yaml
 - name: install httpd package (CentOS)
   tags: apache,centos,httpd
   dnf:
     name:
       - httpd
       - php
     state: latest
   when: ansible_distribution == "CentOS"
 
 - name: start and enable httpd (CentOS)
   tags: apache,centos,httpd
   service:
     name: httpd
     state: started
     enabled: yes
   when: ansible_distribution == "CentOS"
 
 - name: install apache2 package (Ubuntu)
   tags: apache,apache2,ubuntu
   apt:
     name:
       - apache2
       - libapache2-mod-php
     state: latest
   when: ansible_distribution == "Ubuntu"
 
 - name: change e-mail address for admin
   tags: apache,centos,httpd
   lineinfile:
     path: /etc/httpd/conf/httpd.conf
     regexp: '^ServerAdmin'
     line: ServerAdmin somebody@somewhere.net
   when: ansible_distribution == "CentOS"
   register: httpd
 
 - name: restart httpd (CentOS)
   tags: apache,centos,httpd
   service:
     name: httpd
     state: restarted
   when: httpd.changed    
 
 - name: copy html file for site
   tags: apache,apache,apache2,httpd
   copy:
     src: default_site.html
     dest: /var/www/html/index.html
     owner: root
     group: root
     mode: 0644
```


the directory structure is as follow: 
```
ansible/
    site.yaml   
    roles/
        /workstations
            /task
                main.yaml
        /web_servers
            /task
                main.yaml
                /file
                    default_site.index
        /db_servers
            /task
                main.yaml
        /file_servers
            /task
                main.yaml
```

`site.yaml`:
```yaml
 --- 
 - hosts: all
   become: true
   pre_tasks:
 
   - name: update repository index (CentOS)
     tags: always
     dnf:
       update_cache: yes
     changed_when: false
     when: ansible_distribution == "CentOS"
 
   - name: update repository index (Ubuntu)
     tags: always
     apt:
       update_cache: yes
     changed_when: false
     when: ansible_distribution == "Ubuntu"
 
 - hosts: all
   become: true
   roles:
     - base
    
 - hosts: workstations
   become: true
   roles:
     - workstations
 
 - hosts: web_servers
   become: true
   roles:
     - web_servers
 
 - hosts: db_servers
   become: true
   roles:
     - db_servers
 
 - hosts: file_servers
   become: true
   roles:
     - file_servers
```

run the new playbook:
`ansible-playbook --ask-become-pass site.yml`


### [Host Variables](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html#assigning-a-variable-to-one-machine-host-variables) and Handlers
You can easily assign a variable to a single host and then use that variable later in playbooks. You can do this directly in your inventory file. to add host variables, first a `/host_vars` directory should be created inside the root directory of ansible files. this directory will contain variables. </br>
for creating host variables, create file based on host's IP or Domain Name. for instance: </br>
```
/host_vars
    ./172.24.24.11.yaml
    ./172.24.24.12.yaml
```

inside each file we add variables that are going to be used for each hosts for instance: </br>

`vim 172.24.24.11.yaml`:

```ini
apache_package_name: apache2
apache_serviec: apache2
php_package: libapache2-mod-php
```

we can then use these variables inside roles and playbook as follow:

```yaml
- name: restart apache
  tags: apache,ubuntu
  service:
    name: "{{ apache_service }}"
    state: restarted
  when: apache.changed
```


#### Using Handlers
Sometimes you want a task to run only when a change is made on a machine. For example, you may want to restart a service if a task updates the configuration of that service, but not if the configuration is unchanged. Ansible uses handlers to address this use case. Handlers are tasks that only run when notified. </br>
Tasks can instruct one or more handlers to execute using the `notify` keyword. The `notify` keyword can be applied to a task and accepts a list of handler names that are notified on a task change. Alternatively, a string containing a single handler name can be supplied as well

for instance: </br>
we have a playbook that has a task which changes the email of apache service and needs to change the config file.

```yaml
---
- hosts: all
  become: true
  tasks: 
    - name: change e-mail address for admin
      tags: apache,centos,httpd
      lineinfile:
        path: /etc/httpd/conf/httpd.conf
        regexp: '^ServerAdmin'
        line: ServerAdmin mohammadreza@email.com
      when: ansible_distribution == "CentOS"
      notify: restart_apache
```

after that we need to create the `restart_apache` task in a `/handler/main.yaml` directory. note that this file should be created in `/handler` directory. if `roles` are being used in our ansible code then each of these `/handler` files should be created inside each role's related file.

`handler/main.yaml`
```yaml
- name: restart_apache
  service: 
    name: "{{ apache_service }}
    state: restarted 
```



### Templates in Ansible
A template in Ansible is a Jinja2-formatted file used to create dynamic content, such as configuration files, based on variables and host-specific data. </br>
the `template` module is part of ansible-core and included in all Ansible installations. In most cases, you can use the short module name `template` even without specifying the collections keyword. However, we recommend you use the **Fully Qualified Collection Name (FQCN)** `ansible.builtin.template` for easy linking to the module documentation and to avoid conflicting with other collections that may have the same module name.


