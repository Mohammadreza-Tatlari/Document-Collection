### 99-820-3 - 200.1 - Measure and Troubleshoot Resource Usage (CPU and Disk - iostat) ###
#### iostat concept:
iostat is one of other tools to check the utilization of CPU
• iostat -c -h => it will show the CPU usage of system in more human-readable way.
- %user: stands for utilization of cpu
- %iowait: the percentage of time that hard disk should wait for CPU to be idle to work

also we can used to keep printing iostat of CPU on terminal base on 2 parameters 1.interval 2. repeatition
• iostat -c -h 2 5 => it means to print every 2 seconds and for 5 times

iostat also is used to show input/output of block devices such as (disk, iSCSI, SSD, ...) to print them we can use:
• iostat -d => it will print only the block devices 



### 99-820-4 - 200.1 - Measure and Troubleshoot Resource Usage (CPU and Disk - sar) ###
#### sar is another utility that provides report and information about resource (CPU) usage.
• sar => shows CPU utilization
• sar -d => reads  block devices information

important tables:
- tps (transfer per second)
- wr_sec/s | rd_sec/s: read and write per second
- avrgqu_sz (average queue size): the average queue that is being waiting to be processed. (can be useful to check for overloads.)
- svctm: average time that it takes for request to be processes.
- await: is the whole entire time (include the queue time) for the process to be finished

sysstat utilities create a file in /var/log/sa directory which is automatically named base on the months date and reads log from that. the created file is in binary and can only be read by sysstat tools



### 99-820-5 - 200.1 - Measure and Troubleshoot Resource Usage (Memory - free) ###
#### free command is used to display amount of free and used memory and swap of the system 
• free -h => shows the memory and swap usage of our OS
• free -h -s 5 => shows the memory usage human-readable for every 5 seconds

note: 
if memory is less than 1GB then -G won't work. the best is to use `free -h` which handles all.



### 99-820-6 - 200.1 - Measure and Troubleshoot Resource Usage (Memory - vmstat) ###
#### vmstat command shows much more detail about statics of memory usage.  
• vmstate 6 -t => every 6 seconds it shows the statistics and in the end of the line puts the time stamp. it can be used for monitoring data for example every 10minutes and check for interval date.

taking snapshot report from memory usage:
• vmstat -s => it takes memory information snapshot with details. we can also write it will a loop function to print it for a period of time:
• while true; do vmstat -s; sleep 5; done => it will run a loop for every 5 seconds and prints snapshot of memory information.



### 99-820-7 - 200.1 - Measure and Troubleshoot Resource Usage (Disk and Files - lsof) ###
as we know linux treats everything as file. so lsof (list of open files) shows details about all open files that are being running on OS. however it will be a comprehensive file so we use other options to check processes.

• lsof -u (username) | wc -l => it prints all the open files that are being opened by user and it pass the output to wc to count howmany files they are



### 99-820-8 - 200.1 - Measure and Troubleshoot Resource Usage (ps, pstree, top) ###
we sometimes need to check on processes that are on OS for that we use 'ps' utilities.

• ps => using ps alone on terminal only shows all processes that are being run on that terminal with the current user on it. TTY (TeleTypewriter) which means the terminal that we are on that.
• ps -e => shows all the processes other than the ones that are being run on the TTY of user however some may don't have the TTY value which means that they are related to the boot process.
• ps -ef => show full-format information about all process IDs on OS
• ps -af => it is identical to -ef
• ps -af | grep (name of process) => to print out all process that are related to that process.

• pstree => shows the tree format of all process ( for example related processes)
• pstree -a > is used for when we are using pstree in ASCI terminal in order to keep the format readable. (the main format is -G)

• pstree -h -p -Z -a => -h is used to print all current process, -p is used to also show the process ID and the -Z is used to show related security attributes. -a shows more detail of each process.


#### top command
top is a live stream of process and resource utilization.
the top is also interactive, it means inside the top we can use hot keys for different outputs (this interaction can be based on lower/uppercase of word being used.):
• f => list of data that needs to be shown on top table
• r => for renice of a process
• n (number) => top numbers to be shown on top
• h => for help



### 99-820-9 - 200.1 - Measure and Troubleshoot Resource Usage (Network and Bandwidth - netstat) ###
#### netstat: it is very strong tool from "net-tools" and has a broad range of usage. for example checking all routes on OS or getting detail information about interfaces, ports and traffics. and different protocol conditions.
• netstart -r => is used to list all routes that are being used on OS.
• nestart -s => prints a full statistics of network information.
• netstat -tulpn => it is a command way for listing all listening ports which are TCP (t) and udp (u) with the processes and services that are using them -n is used for stopping the reverse DNS look up. -p is used for process ID



### 99-820-10 - 200.1 - Measure and Troubleshoot Resource Usage (User Information - w) ###
w which stands for who is a command that is used to check detail information about users that are aconnected to OS
w prints the Terminal, name, load average, time , etc of the user that has been using the OS
• w -i => is used to stop the reverse DNS (if exists) and shows IP address of remote users



### 99-820-11 - 200.2 - Predict Future Resource Needs (collectd Introduction and Configuration) ###
#### collectd is a utility that collects information of the host system. it also uses specific plugins if a data format that helps to visualize the data on web. collectd helps to predict future resource needs on OS.
collectd can be installed from collectd-core packages.

in collectd.conf file we can activate different plugins for monitoring different services on OS.

rrdtool: it is a plugin that allows to monitor and visualize data over web.



### 99-820-12 - 200.2 - Predict Future Resource Needs (collectd Key Files and Locations) ###
in usr/share/collectd/ there is a database file called types.db which is stored in plain text. it contains all the data that can be collected from hosts.
also collectd is equipted with remote gathering data tool. it does that by configuring address in RRD tool
/var/lib/collectd is location where the collectd is writing rrd file and reading from
inside rrd there are several files (if other hosts are added) that the rrd will read values from them and monitor their data.



### 99-820-13 - 200.2 - Predict Future Resource Needs (collectd - Display Statistics for Capacity Planning) ###
for using collectd web dashboard, few packages need to be installed. we can use lighttpd for web service.
1. lightthpd, php , php-cgi, git (git is used to clone a repository from git which containes fundamental material to setup web dashbaord for collectd and RRD.

• we need to enable (uncomment) the ` cgi.fix_pathinfo=1 ` in php.init config file.
• we need to do ` lighttpd-enable-mod fastcgi , lighttpd-enable-mod fastcgi-php` for lighttpd 
	• restart the lighttpd service
• clone a dashboard in /var/www (the desired dashbaord for cloning is removed from repository :(  )
• then go to the host IP/cgi (or the name of that dashbaord related to collectd) 

collectd can also be used for monitoring services



### 99-820-14 - 200.2 - Predict Future Resource Needs (Awareness of Other Monitoring Tools) ###
Nagios
Nagios Core is freely available and is a open source core monitoring system.
however, the Nagios XI is full enterpise package.
Nagios Core queries information from the collectd deamon and then create graphs and static charts.
https://www.nagios.com

MRTG
Multi Router Traffic Grapher (MRTG) is a network admins tool that offer enterpise extentions to MRTG including scrutinizer, flowpro and replicator.
it reads information from routers and switches and creates logs for that.
it is written in perl and works in Unix, Linux and windows systems.
https://www.mrtg.com/

Cacti
Cacti is a complete network graphing solution desinged to harness the RRDTools data storage. it is very advanced and robust. besided being featureful, it is intuitive and has easy to use interface.



### 99-821-1 - 201.1 - Kernel Components (Source and Documentation for 2.6.x and 3.x Kernels) ###
each distro has its own set of kernel components and some components may vary between each.
#### uname is a command line tool used to print system information however it can be used for other kernel operations. 
• uname -a => it gives information about the OS kernel

in some linux distro installation the source code of kernel is also available in OS the path is:
• /usr/src/kernl or /usr/src/(name of kernel)

however if its not present it can be installed by ` apt install kernel-devel` (which is for centOS7)

docomentation of kernel should usually be installed with the kernel source code but if not it can be installed by:
• apt install kernel-doc => if no version is passed to it, it will install the one that is being used on OS.

the location of kernel doc can be also vary:
- usr/src/kernle/(linux-kernel)/Documentation
- /usr/share/doc


Ubuntu
in Ubuntu Kernel Source packages is different for getting if its not present.
• get-apt source linux-image-$(uname -r) => it will download the current linux kernel source which is running on OS.
note:
other versions can be find with ` apt-cache search ` and base on finding that kernel can be installed.



### 99-821-2 - 201.1 - Kernel Components (2.6.x and 3.x Kernels - Terms) ###
in /boot directory we can find all the files that linux needs for booting process.
there are two types of images that comprise the kernel.
first is called the z image which stands for zipped image which is compressed image of kernel. and in old systems it was used to be kept in low capacity memories.
in later version such as 2.4 and above, there was a Big zImage as the kernel got bigger and RAM got larger.
the z images are used for embedded systems where as the Big ZImages are used in large RAM and resource systems.



### 99-821-3 - 201.2 - Compiling a Kernel (Preparing the System - Dependencies) ###
for compiling a linux we first need to have tools. each distro has its own developers tools. these tools help us to create and complete our linux kernel

for CentOs it is " Developement Tools" and should be installed in Group
• yum groupinstall 'Development Tools" & yum install ncurses-devel qt-devel hmaccalc zlib-devel binutils-devel elfutils-libelf-devel


for Ubuntu the packages and their installation is a little different we use:
• apt-get install make gcc libncurses5-dev 
• apt-get build-dep linux-image-$(uname -r)

you might encounter an error which is:
 You must put some 'deb-src' URIs in your sources.list

for example:
for that we need to add resource packages URL lists. to do that edit the file:
vim /etc/apt/resource.list
add these lines to it which are the URL of related packages:

deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse

deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse

deb http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse


make command
make is a command tool that base on input that is given to it it compiles and output the target result.

note:
these steps should be done in /usr/src/(linux kernel directory)

before we begin creating our kernel, we first need to do couple of things
• make distclean => it cleans and remove everything related to distro such as backup files and left over files.
• make mrproper => clean out the entire kernel source tree and bring it back to the state as it was when you first unpacked it.



### 99-821-4 - 201.2 - Compiling a Kernel (2.6.x_3.x General Kernel Compilation Process) ###

( NEEDS A DEDICATED TIME TO COMPLETE. THE COMPILING TAKES SO LONG)



### 99-821-5 - 201.3 - Kernel Runtime Management and Troubleshooting (LKM- Loadable Kernel Modules) ###

LVM are a way to extend the functionality of the linux kernel without requiring a full kernel rebuild. think of them as plug-ins for the kernel.

####lets break down LVM:
- Code modules: LKMs are peices of compuled code tha can bed ynamically loaded into the running kernel such as new drivers, file systems or network protocols , etc.
- Dynamic Loading: they can be loaded and unloaded while the ystem is running.
- Kernel Space: LVM runs in kernel space which means it has direct access to hardware resources. which can be an potential danger.

LVM are used for:
- Modularity: to keep small and efficient by only loading the necessary functionality.
- Driver Support: when you plug in a new device, system can often automatically load the dirver module.
- Flexibility
- Third-party developments: Vendors can distribute drives for their hardware as LKMs without needing to modify the core kernel.



### 99-821-6 - 201.3 - Kernel Runtime Management and Troubleshooting (depmod and modules.dep) ###

linux modules are located in /lib/modules/ & lib/module.d/

#### depmod
depmod is a utility in linux that generates dependency information for loadable kernel modules (LKMs). these information is crucial for the modprobe command to work correctly.

what does it do?
- analyzes modules and examines the kernel modules in a specified directory ( /lib/modules/$(uname -r) ). reads the module fules and determine their dependencies.
then based on analysis creates a module.dep (dependencies) file ( modules.alias , modules.symbols file) in the modules directory. this file contains a list of modules and their depedencies. 
the Modules.dep file allows modprobe to automaticallt load all the necessary dependencies when you try to load a module.

usecases:
- Kernel Updates: after compiling or installing new kernel the depmod must be executed.
- Module installation: like after installing a new kernel modules ( new Driver), you should ron depmod
- Troubleshooting Module loading
- Module Management: keep track of module dependencies and help to load them correctly.

after running ` depmod `. we can check the /lib/modules/(linux version)/module.dep:
in each line which is showing the .ko file the line is seperated with double colon ( : ) which it means the dependencies of each kernel module to another kernel module.


#### mapped module files
some files are named for instance ' modules.usbmap ' and they show the interfaces that are detected on OS for hardware drivers and modules.



### 99-821-7 - 201.3 - Kernel Runtime Management and Troubleshooting (Listing, Adding and Removing Modules) ###

for listing and getting brief information about modules we can do:
• lsmod => it will list all modules on OS
this listing helps us to determine how safe is it to remove a module, or what dependencies are required for specific modules, or whether a module is needed to free up memory space.


two ways to install a module:
#### 1. using insmod and modinfo
to install a new module we can use ` insmod ` however it is difficult cause we first need to find the exact module .ko (kernel object) name.
to do that we can use ' modinfo ' which shows information besides exact kernel object name.

• modinfo (name of module) => to receive information and exact name of module.
• insmod (exact name of module) => to install the module
example:
insmod /lib/modules/6.8.0-52-generic/kernel/drivers/char/lp.ko

#### 2. use modprobe
modprobe will probe for that module with same name and if it is not installed it will install it.
• modprobe pl => it will loke for .ko file of the pl module and install it.


#### remove a module with rmmod
rmmod will remove a module but be aware to that some module may be dependencies of other modules.
• rmmod (name of module) 

information and parameter for each module can be changed. it can happen by modprobe
• modpropbe pl reset=1 => it will set the reset parameter of pl to 1 so when it is installed it will be reset.

also modprobe can also delete modules to with 
• modprobe -r 

modprobe list
in /etc/modeprobe.d/ there are several files that contain information.
the blacklist are the modules that are not allowed to be installed and based on each. for eaxmple we don't want to load specific nvidia driver so we can put it in blacklist modules



### 99-821-8 - 201.3 - Kernel Runtime Management and Troubleshooting (Viewing and Changing Kernel Parameters in _proc_sys and U ###

/proc/sys file system is a memory based file system that is mounted on the /proc

in /proc/sys/dev/ we can find useful information such as " spintime " of each Kernel module.
the spintime is the time that the module takes in order to run.
the value of spintime can be change manually however, it is the best to use ` sysctl `

sysctl is a tool to confgure kernel parameters. for example we can list all parameters that sysctl can change for each module with:
• sysctl -a => it will list all
• sysctl -a | grep (module name) => for finding parameters of desired modules.

example:
sysctl dev.parport.default.spintime=510 => it will set the spintime of parallel port to 510.

note:
this changes are not permament so if we want to make these changes permanent after our test. we should modify the sysctl.conf file in /etc/ directory.

to make a parameter permanent we need to add its value to the /etc/sysctl.conf file with the new value. so the sysctl will read the value from that.
for example adding this line to the sysctl.conf file to override:
• dev.parport.default.spintime = 500



### 99-821-9 - 201.3 - Kernel Runtime Management and Troubleshooting (Displaying Information About System Hardware) ###

#### lspci
hardware devices such as the one connected by chasi or via the bus or PCI (Peripheral Component Interconnect).
all these hardwares can be listed and available with ` lspci ` command.

• lscpi => it will list the data such as slot, position, bus number, type, manefacture, model information and revision if there are available.
example:
00:18.0 PCI bridge: VMware PCI Express Root Port (rev 01)

• lspci -vvv => goes into much more (almost all) verbose mode, shows, capability, I/O, flags, subsystem, motherboard , etc.

we can find the kernel module with that are associated with devices that we have on our system.
• lspci -k => it filter out base on modules in use

#### lsdev
lsdev gathers information about hardware devices installed on our system base on information in /proc directory.

these are good information if we are writing a device driver or working on them or we are going to write or edit an interface.


#### lsusb
on later linux kernel above v3 we have lsusb which is restricted to only connected USB devices. it is similar to lspci.

we can specify information only related to that devices by givin the ID of it:
• lsusb -v -d 0e0f:0003 => it will list description about that device


on some distros such as CentOS the plugged or detected devices are logged in messages file inside /var/log/ which can be checked.
• less var/log/messages 

on Ubuntu and Debian Systems the location is in /var/log/syslog
• less var/log/syslog 



### 99-821-10 - 201.3 - Kernel Runtime Management and Troubleshooting (The Device Filesystem - udev) ###
in past devices that could be read from linux OS had file in /dev directory and dev file could read from them

#### udev
the detection and probing of the devices that are connected to OS is done by dev daemon which is called ` udev `

the configuration related to rules that udev is going to confirm for detecting devices are located in ` /etc/udev ` &  ` /etc/udev/rules.d/ `
each rule has a number from 1 up to 999. the higher the rule the more prior it is to other rules
the data inside each rule defines what in modules can support.

#### udevadm
to monitor what happens when a devices is connected to system we can use udevadm which is a replacement for udevmonitor which used to exist in version 2.6 below. udevadm allows what happens when we insert new devices to our system.

• udevadm monitor => it will keep watching the ports and I/Os and log what happens.



### 99-822-1 - 202.1 - Customizing a SysV-Init System Startup (LSB - Linux Standard Base Specification) ###

Linux Standard Base (LSB is a project by several Linux distributions under the organizational structure of the Linux Foundation to standardize the software structure. including the filesystem hierarchy.

LSB is designed to be binary compatible and produce a stable Application BInary Interface (ABI) for independent software vendors. to achieve backward compatibility, each subsequent version is purely additive, it means that interfaces are only added and not removed.
this allows the developer to rely on every interface in the LSB for a known time and also to plan for changes cause the LSB adopted ints own deprecation policties.

LSB 5.0 is the first major release that breaks backward compatibility with earlier versions.



### 99-822-2 - 202.1 - Customizing a SysV-Init System Startup (SysVInit Boot Process) ###
Traditionally system V init was used to start other services. but V init had shortages. so upstart and systemd were developed.

sysV uses runlevels concept to define sequence of services that are going to be loaded. in each runlevel specific amounto fshell scripts is proecssed to reach the state we desired.

<pre>
runlevel		Redhat							Debian
0			System Halt (do not set as default)	System halt (not as default)
1			Single user Mode					Single user mode	
2			Multi User without NFS			Full multi User mode with GUI
3			Full Multi user mode				--same as 2-- --unused
4			--unused						//
5			X11/Full multi user Mode			//
6			reboot (do not set as initdefault)		reboot(do not set as default)
</pre>
run level 7 8 9 but not standardized

run level 1 is for serious OS troubleshooting
run level 3 is the general server run level without GUI

the run level are defined in /etc/inittab in CentOS and are defined in /etc/ with name rc0.d to rcS.d

in CentOS there are  rc.d folders in ` etc/rc/  ` which contains the configuration of each runlevel and it can be modified
the rcsysinit is the file that contains the most based of run level for the OS however in ubuntu based system it is called /etc/rcs.d

in each rc directory there are scripts that starts with S which start a service and those with K that kills the specific services and the number after them is the priority of that script in running.



### 99-822-5 - 202.1 - Customizing a SysV-Init System Startup (Changing Runlevels) ###

#### runlevel
we can initialize a run level by using the command ` runlevel ` for more information on runlevel use its manual page.
• runlevel => runlevel alone will print the run level that we are currently on it. if we are on a linux server it might be 3 and if we are on desktop it might be 5

we can also use ` init ` for switching between runlevel.
• init 6 => it switches to run level 6 which is rebooting

####telinit
it is also another command which is merged with init for changing the run level.



### 99-822-6 - 202.2 - System Recovery (Understanding the Boot Process) ###
(Borrowed from LPIC 1 :) )

MBR (Master Boot Record): Legacy BIOS -> 0,0,1 (Clander 0, Side 0 , Sector 1) is the first location of Hard disk that is around 512 byte and contains information about boot loading. but in modern computer and more advanced boot loader the small part of the loader is placed in that location and computer reads from it and initiate the rest of boot loader in other locations. the memory that is being used Is called ?MBR?

GRUB (Grand Unified Bootloader): started to replace the older LILO (Linux Loader). the first version (1) is GRUB legacy and started in 1999 the second version started in 2005 and is a complete rewrite of version 1. its menu based system which Kernerl or Chainloader is being selected to boot. it is also possible to edit the menu on the fly or give direct commands from a command line.
Grub configuration is possible via grub config file

UEFI uses stages to boot the system and these stages are like checking the security of OS and ...

definition of chainloading: when a boot loader loads another boot loader. for example when linux bootloader needs to start a windows system

Installation and configuration of Boot and Boot loader part2 GRUB2

It is possible to change the configuration of GRUBs in linux systems but it depends on firmware and type of Bios or UEFI
to do so we can check out /boot/grub/grub.cfg file or with similar name.
in the grub file most of configuration and options are avialable and by changing it we can change the GRUB behaviour. it is possible to add new menuentry for it and config sda location and more changes.
all GRUB2 configurations are not placed inside a single file so for more conviniences grub-mkconfig file is created to implement changes to grub interfaces.
so in etc/default/grub or etc/grub.d there is a grub-mkconfig and you need to issue it and take an output form changes to it into another file:
grub2-mkconfig -o (or >) boot/grub2/grub.cfg

options of grub2:
menuentry: defines a new menuentry
set root: defines the root where /boot located
linux,linux16: defines the location of the linux kernel on BIOS systems
linuxefi: defines the Linux kernel on UEFI systems
initrd: defines the initramfs image for BIOS systems
initrdefi: defines the initramfs imafge for EUFI systems

sometimes when new menuentry is being created for linux system if the sda location does not come with proper place it will redirect you to a busybox environment which is a small linux system and can run some basic commands 



### 99-822-7 - 202.2 - System Recovery (GRUB - Legacy Bootloader) ###
one of the disadvantages to grub was the disability to read hard drives from UUIDs which it means that the configuration would change if the hard disk for instance is changed from the usb input or PCI.
grub legacy used to not support all Operating Systems.

in grub legacy the configuration is much simpler. for example we can defined the timeout and splashimage screen.

note:
the (hd0,0)=(first hard drive, on first partition) in grub legacy is referred to for instance the hda. and the hda1 is also known as (hd0,0-1)
but the "hdb" is referred to (hd1,1). so the alphabetic is used as to point to the array in hard disk.

the grub also has some security issues for example we can edit the grub menu from the booting process and put the ` s ` option as `single mode` in the end of the boot selection and come up without asking for password.


#### how to secure grub with encrypted password
after boot up, we can use ` grub-md5-crypt ` command to generate an encrypted password.
then we need to add the generated encrypted md5 text to the grub as:
/boot/grub.conf:
• password --md5 $1R4X0/$A25e0f3/0ra0esdf..dj42

note: based on where we put the password --md5 it will prompt us for the pass, for example we can put it before the second entry bootloader.



### 99-822-8 - 202.2 - System Recovery (GRUB 2 - Modern Bootloader)
grub 2 is the replacement of grub legacy in modern architectures. for instance the shortage of using UUID for defining the hard disks.
grub 2 also allows to boot from LVM, encrypted devices or RAID devices.

as the grub2.cfg/grub.cfg is observed it is consist of section for example " /etc/grub.d/00_header " and /etc/default/grub.
these sections are actually read from the /etc/grub.d/

for instance in /etc/default/grub we have:
GRUB_DEAFULT=saved , the "saved" means that each we change configuration on the grub the saved changed configuration will be applied to functionality.

to update grub2 after changes we need to run a command:
• in Ubuntu: update-grub
• CentOS: grub2-mkconfig -o "$(readlink -e /etc/grub2.conf)" , also remember to have a backup from the grub.cfg file that we are going to place it with the new grub file.

if we want to add customized grub configuration it is best practice to add it into ` 40_custom ` file in grub directory.

we can configure our grub by adding condition or extra line at the end of our BigZImage in our entry. for instance  ` init=/bin/sh `  which will bring the system in shell mode.
however for this instance the configuration won't be saved unless we touch ` /.autorelable `
• touch /.autorelabel



### 99-822-9 - 202.2 - System Recovery (Filesystem Recovery - fsck) ###
#### fsck
there are some conditions which the filesystem might break or corrupt due to reboot or misconfiguration. in these stuations the OS itself will try to automatically check and repair them out but if it couldn't we can do it manually by the fsck tool.
fsck is a command tool that checks for filesystems and repair them if any problem is detected based on its script.
but first we need to unmount our filesystem for instance /backupstuff and them by using ` df -h ` we will see that there is no filesystem named /backup anymore but we know exist by checking ` cat /etc/fstab `
then we can run fsck /dev/(name of hard disk device in fstab) and repair it if it need.
• fsck /dev/xsdd 



### 99-822-10 - 202.3 - Alternate Bootloaders (Awareness of LILO, Syslinux, EXTLinux, ISOLinux, PXELinux) ### 

#### LILO (Linux Loader): older bootloader and replaced by Grub

#### SYSLINUX: associated with the syslinux project. intended as one of several boot loaders that do only specific things.
Designed to be placed on a disk

#### EXTLINUX: same as syslinux project alternatives. 
it supports EXT2/3/4 filesystem on USB.

#### ISOLINUX: to do specific things and DEsinged to make bootable CD-ROM (ISO 9660 filesystems)

#### PXELINUX: used for network bootable devices and is associated with the syslinux project.

<br>
<br>

### 99-823-1 - 203.1 - Operating the Linux Filesystem (Displaying Filesystem Mounting Information) ###

we can get information about filesystem base on mounts where the file system are located.<br>
my using ` mount ` command alone we can get information about file systems.<br>
• `mount `=> it will print out the filesystem that are mounted on system.<br>
• `df -h `=> it is also a shorter way to check mounted filesystems.<br>

mount command reads this data from mtab file which is located in `/etc/mtab`

my using ` mount -n ` command we can stop mount and umount to write on mtab file which can be due to security or practical reason.

however the most up to date file related to mount is in ` /proc/mounts ` <br>
this file is updated by kernel and contains more information.<br>
• `less /proc/mounts`



### 99-823-2 - 203.1 - Operating the Linux Filesystem (Mounting and Unmounting Filesystems Manually) ###
sometime we might need to unmount a filesystem but its not possible because there are processing on them. so we might need to do it with: <br>
• `umount -f /mnt/data`  => it forces the unmount process

but we can check which process is using that filesystem and stop or manage them. it is possible by fuser.<br>
• `fuser /` => it will print out all process that are using the " / " filesystem which is root.<br>
the values for example " 499rc ":<br>
the 499 is the process ID, the " r " meanst that it is a root directory and "  " stands for the current directory that we are in it.

• `fuser -v /` => it gives more information.

to kill all process that are using the specific filesystem we can use -k options.<br>
• `fuser -k /mnt/backup` => it will kill all process that are using /mnt/backup.

<br>
<br>

#### mounting a filesystem
**note**:<br>
most of time the mountable filesystems are located in /mnt, /media (if media is inserted) , /run.

example:<br>
we are going to mount a /dev/sdb1 to a filesystem called /mnt/data so we can use the data inside the /dev/sdb1<br>
note:
> remember to define the filesystem type by mkfs.
• `mount -t ext3 /dev/sdb1 /mnt/data` => in this case we define the type of disk device which is ext3 (extended 3) and mount it in /mnt/data.<br> so if we go to the data directory we will be able too see the data that was written in /dev/sdb1.

note:<br>
we can use options for mounting a disk or device on our OS, these options can be related to the user password that it needs to have access to the disk data, the protocol that we are using for example we might want to mount from a network device or read-only condition
for example:<br>
•` mount -o remount, ro /mnt/data `=> by passing -o (option) we define that we are going to give options. the remount will mount the filesystem agaim and the " ro" will set it in read-only mode.<br>
we can test it by writing something in it:<br>
•` echo "test this" > /mnt/data/testfile.txt`

we can reissue the command:
• `mount -o remount, rw /mnt/data `



### 99-823-3 - 203.1 - Operating the Linux Filesystem (Mounting Filesystems Automatically with /etc/fstab)
there are cases that we might have unmounted a filesystem but we need to mount them back or the mount needed files are alot. for such cases we can use options of mount system.<br>
• `mount -a -v `=> this command will mount all filesystems mentioned in fstab expect tfor those whose line contains the noauto keyword. I used -v to see the process in verbose mode.

if we want to create a manual input for our device path we need to edit it in fstab file. for instance:<br>
inside ` /etc/fstab ` these inputs should be define in line:<br>
`(device path ) (file path point) (filesystem type) (mount options)  (dump number) (sync number)` <br>
for example:<br>
`/dev/sdb1   /tmp/data   ext4    defaults     0 0`

verify that it is mounted after mount -a with:<br>
• `df -h` => it will list all in used filesystems.

however what if we want to change the device path or we need to change its name. so for that we need to change its path each time it is changed on fstab file. for that we can use other tools to make it more dynamic.

#### e2label
e2label changes the label of device path. think of it as a variable that hold the path of our device that we want to assign a filesystem to it. however it has some limits for instance it only supports ext2,3,4 and not NTFS or FAT.
to use e2label we can do:
1. we need to label the dev<br>
`e2label /dev/sda1 (label name)` => this will set the (label name) for that specific file path. for example: <br>
`e2label /dev/sdb1 monitoring_data`  <br>
2. then we can add it into our /etc/fstab file:
instead of ` /dev/sdb1   /tmp/data   ext4    defaults     0 0 `
we write: ` LABEL=monitoring_data /tmp/data   ext4   default   0 0 `

however if anyone who have access to this file can change its value so the problem is the access. for example a person with right access can change the label with e2label to something else.


#### blkid
there is another way to mount our device to filesystem in more reliable way and it is by adding it with its UUID
by using blkid we can check the UUID of each block device that we want to mount on our filesystem.<br>
• `blkid | grep /dev/sda1` => it will list the blkids and grep to the line that is related to /dev/sda1 and will give us its UUID (Universal Unique Identifier)<br>
it reads the data from the path ` /dev/disk/by-uuid `

then we can add it to our fstab and use it instead of the path in /dev/sda1<br>
• `UUID=87e29c4f-45f3-46a9-babd-d31846f882c6    /mnt/data   ext3   defaults   0 0`

for the `fs_mntops` (the fourth field) we can check the man fstab.

##### sync
it used to synchronize cach that is writen for persistent storage. however in modern OS and devices due to their robustness they are not used.



### 99-823-4 - 203.1 Operating the Linux Filesystem (Swap Space) ###
swapoff and swapon are used to enable or disable swap in Operating System<br>
• `swapon -s `=> it will print out the filename and size of swap -s means --summary<br>
• `swapoff -a` => it turn off all swap spaces and with swapon -s there will be no more swap file.<br>
• `swapoff /dev/dm-0 `=> it will swap off specific swap paritions.<br>
• `swapon -a `=> it will enable all swaps it is the default option.<br>

also swap usage can be monitor in various places like "top".

the swap file are defined in` /etc/fstab` with swap file system type and swap file path.



### 99-823-5 - 203-2 - Maintaining a Linux Filesystem (Filesystem Types and Creating Them) ###
the ext4 (extended 4) is the default filesystem type in most of linux, except the Redhat distribution like CentOS that after version 7 switched to xfs filesystem.
(Borrowed from LPIC-1)
- ext2 (extneded 2):  There is no journaling in ext2,
>note:
> journaling: its a way that writing on disk works. it checks the journal list where it has been writing data or if the data that is for example interupted is completed or its incomplete thus it will rewrite it or keep up the rest of procedure
- ext3:ext2 + journaling, max file size is 2TB and max filesystem size is 16TB
- ext4:current version of ext, max file size is 16TB and max filesystem size is 1EB (1000*1000TB)
- XFS:journaling, caches to RAM, great for uninterruptible power supplies, Max file and filesystem size is 8EB
- VFAT:FAT32, no journaling, good for data exchange with windows, does not understand permissions and symbolic links
- exFAT:Extended FAT. A newer version of FAT which is used mainly for extended device which should work on all machines; like USB disks
- btrfs:A new high performance file system. Max file and filesize is 16 EB. Has its own form of RAID and LVM and build-in snapshots and fault tolerance and data compression on the fly.
btrfs is one of the most popular file formats

> be careful when formating a file thats why some computers and OS do not recognize other disk or blocked devices

• `fdisk -l `=> by using fdisk -l we can see all filesystems with information detail on OS.

after creating a partition in fdisk and writing it down we are able to decide what kind of partition we can assign to that.

for formating our partition we can use ` mkfs `

#### mkfs 
mkfs (makefile system) helps us decide to build a linux filesystem for our partition.<br>
• `mkfs -t -v ext4 /dev/sdb1` => it will format the /dev/sdb1 with ext4 format and in verbose mode.<br>
note:
> we cannot format a file with mkfs on a drive and it is only possible for partition.

`mkfs -t` is actually a pointer to the /sbin/mkfs.* which you can `ls` and check them out<br>
`/sbin/mkfs.ext3 = mkfs -t ext3`



### 99-823-6 - 203.2 - Maintaining a Linux Filesystem (Change and View EXT Based Filesystems) ###
#### fsck
we can use fsck to check the filesystem of our device. however to do that we first need to unmount our devices.
the fsck files are similar to the mkfs files and are located in /sbin/fsck*
• `ls /sbin/fsck* `=> to print all files related to fsck.

to check out the filesystem of a device we do:
1. first we unmount the file<br>
• `umount /dev/sdb1`
2. then run the check on it<br>
• `fsck /dev/sdb1`


#### dumpe2fs
if we want to print and dump out all information related to our file system we can use ` dumpe2fs ` however it only dump filesystem in ex2,3,4.
if we want to only print out the superblock information and not the block group we can use:
• dumpe2fs -h /dev/sdb1 

informations such as inode size and reserved size are important for example Reserved block which shows the blocked that only super user (root) can write on them.

#### tune2fs
to manipulate the data configured on file systems we can use ` tune2fs ` it is onlt related to ext file systems. remember, the information related to physical partitioning cannot be changed by this tool and needs repartitioning.<br>
• `tune2fs -m 0 /dev/sdb1` => it will change the percentage of Reserved Block for root to 0%.

#### debugfs 
we can prompt into a debug shell and interact with our file system.<br>
we need to unmount the file before debugging due to: <br>
1. stop integrity of data between OS and file if we needs predicatable behavior and for exclusive access. however if data is not going to change, then unmounting is not necessary.

- `debugfs /dev/sdb1` => it will go into the debug interface.
	- ` stat (filename)` => shows the status of file in debugfs in more detail.



### 99-823-7 - 203.2 - Maintaining a Linux Filesystem (Change and View XFS Based Filesystems) ###
before working with XFS file system we first need to install its tool-kit.
Ubuntu:
• apt install xfsprogs
RH:
• yum install xfsprogs

to create a XFS file system we can then run:
• mkfs.xfs /dev/sdb2 => it will format this disk partition into file system.

#### xfs_info
xfs_info will print information abou the xfs partition. the output is similar to one that is created when we first use mkfs to create xfs file system.
• xfs_info /dev/sdb2

#### xfs_repair
xfs_repair is used to repair the broken XFS file system. remember to unmoun the file system before running the repair. it has 7 phases for troubleshooting from detection to verification.
• /umount /dev/sdb2
• xfs_repair /dev/sdb2

note
> sometime it may take a long time in order to pass these phases due to the hard disk partitioning or data.

to only run the check and not the repairing we can use -n options for only checking instead of xfs_check.
• xfs_repair -n /dev/sdb2


#### xfsdump
we can use xfsdump to get backup <br>
• `xfsdump -f (destination of backup) (the file)`

xfsdump has 3 levels of backup.<br>
**0** is for backup all files with no condition <br>
**1** is for backup only files that are different from previous backup. <br>
**2** is for backup only the files that the content of it is changed<br>

(needs more learning) <br>
#### xfsrestore
the backup file that xfsdump provides is a binary and is accessible via xfsrestore. <br>
we use xfsrestore to restore the backup file.<br>
• `xfsrestore -f (the binary backup file) (the destination)`



### 99-823-8 - 203.3 - Creating and Configuring Filesystem Options (Creating Swap Files and Partitions) ###

there are two ways to create a swap file. first is to make a separate partition for it and the second is to make a zeroed file and assign swap file system to it.
#### paritioning a swap file
we can use fdisk and define a partition with space and then change its type with to swap file.

then we need to use ` mkswap ` and pass the new created swap parition to it.
• mkswap /dev/sdb3 => it will create that parition as a swap file.

after that, for auto mounting, we add entry to fstab file
• /dev/sdb3 	swap 	swap 	defaults 		 0 0

then we can check status and run activate swap file
• swapon -s => for status
• swapon -a => to active swap we created


#### creating a swapfile with dd
another way to create a swap file is to use ` dd ` command to convert file into a zero spaced file and assign it as a swap file system.
first we create a file with name ` myswapfile ` in /root/
then we zero its space with `dd`:
• dd if=/dev/zero	of=/root/myswapfile	bs=1M	count=1024 (1GB) => it will fill up 1GB file of myswapfile and will be zeroed

change the ./myswapfile permission so it will be secured.

use mkswap /root/myswapfile to make that file as a swap file system
• mkswap /root/myswapfile

then add that into fstab.
• /root/myswapfile	swap	swap	sw	0 0

then run ` swapon -a ` to activate all swap files



### 99-824-1 - 204.1 - Configuring RAID (Introduction to RAID Types) ###
Redundant Array of Independent DIsks (RAID)
it provides a way of storing the same data across different dievices to create redundancy, speed or both. the I/O can be better distributed and improve performance (RAID 0) or create multiple layers of redundancy that protect against device failure (RAID 1 or 5)
used to increase Mean Time Between Failure (MTBF). redudancy increases fault tolerance and ability to recover from faulty device or transaction.


#### Hardware and Software RAID
Hardware RAID: controlled by a hardware controller (a card orspecial implementation on the motherboard). and can be controlled from BIOS of the Motherboard.

Sotware RAID: your kernel will configure and manage the RAID array instead of a hardware controller.


#### RAID Types:
#####RAID 0
RAID type that designed for speed rather than redundancy and is common on desktop laptop devices.
RAID 0 writes all data to multiple disk devices as though they were a single device. thi is often called striping where some data is written to the first thensome to the second.
it increases the I/O capacity due to sharing the data through disks.

##### RAID 1
referred to " Mirroring " as two or more devices will appear to be a single device. data that is written on one disk will be duplciated entirely on all others.
this increases redundacny and fault tolerance but is generally at the expense of performance.

##### RAID 5
RAID 5 will require at least three devices in order to implement. all the derives in the array wil be used with " parity " data spread throughout all disks in a " round robin " approach. (first disk A, then disk B, then disk C, etc).
parity data is derived from the data on all other deviecs and can be used to rebuild the storage pool in the event of failure.

##### Other RAIDS
RAID 4 : Same as RAID 5 expect that a single devices is used to store parity data.
RAID 10: called RAID 1+0, combines both RAID 1 and RAID 0 with advantages of both.
RAID 50: called RAID 5+0, combines both RAID 5 and RIAD 0 with both advantages.



### 99-824-2 - 204.1 - Configuring RAID (Preparing Your Devices for Software RAID) ###
to create a raid disks we first need to make paritioning on our disks with fdisk and make the parition type as ` linux raid auto (fd) `. 
so we define a primary partition.
then assign the size to it (also we can use cylinders of 25 50 75 in order to practice)
and change its type to fd.
by creating several (three parition) we can keep on working on RAID.



### 99-824-3 - 204.1 - Configuring RAID (Configuring Your RAID Device) ###
#### mdadm
mdadm is used to control and manage RAID on linux OS. <br>
to use " mdadm " on some distros its packages need to be installed.<br>
• `apt install mdadm`

then we need to create a " md " file and assign a RAID type with all partition that are defined as RAID paritions. for example:<br>
• `mdadm -C /dev/md0 -l raid5 -n 3 /dev/sdb1 /dev/sdc1 /dev/sdd1 -x 3 /dev/sdb2 /dev/sdc2 /dev/sdd2` => in this command we first create a md file with name /dev/md0 and then we define the raid type with " -l " and then assign 3 paritions with " -n " and the path of those paritions and in the end we also defined the extra paritions in order of the failover with the path of those extra (spare) parititions.

we can confirm it by:<br>
• `ls -al /dev/md*`<br>
• `mdadm --detail /dev/md0` => it will list detailed information about the md file and RAID.

we can also use the mdstat to check all mdadm informations.<br>
`/proc/mdstat`

to see whether the RAID is active or not we can do:<br>
• `mdadm --detail --scan --verbose` 

note: 
> the data that mdadm --detail --scan --verbose provides is the data that is needed to define in fstab in order to make the raid persistent after boot up. 
> so we can write to the /etc/mdadm.conf and then direct its path in fstab.
• `mdadm --detail --scan --verbose > /etc/mdadm.conf`

then after writing the mdadm output into its ./mdadm.conf file we define a file system path and let mdadm to mount its RAID on that.

- `mkdir /mnt/raid5`
- `mkfs -t ext4 /dev/md0`
- `mount -t ext /dev/md0 /mnt/raid5`

then add the mount point into " /etc/fstab " file:<br>
- `/dev/md0 	/mnt/raid5	ext4		defaults	0 2	#with the sync active (optional)`

test the result by unmountin and mounting it again<br>
- `umount /mnt/raid5` 
- `df -h` => to check it

mount it with fstab:
- ` mount -a` => to mount all automatically from fstab
- `df -h` => to check it out.



### 99-824-4 - 204.1 - Configuring RAID (Managing Failover and Recovery of RAID Devices) ###

we can test our spare devices by assigning a fail flag to our working paritions for example:<br>
• `mdadm --fail /dev/md0 /dev/sdb1` => it will set that partition as faulty and will bring up one of the spare disk that was defined
you can check that by:<br>
• `mdadm --detail /dev/md0`

we also can add more spare paritions if exists with: <br>
- `mdadm --add /dev/md0 /dev/sdb3`
- `mdadm --add /dev/md0 /dev/sdc3`
- `mdadm --add /dev/md0 /dev/sdd3`

note
> after adding the new paritions we have to rewrite the mdadm.conf file with:
• mdadm --detail --scan --verbose > /etc/mdadm.conf



### 99-824-5 - 204.2 - Adjusting Storage Device Access (iSCSI Network Storage - Target Configuration) ###
#### iSCSI
for managing target iscsi target storage we first need to install its packages.
in Ubuntu we use ` tgt ` packages.
• apt install tgt 

when we are using iSCSI we are not sharing a file from file system we are actually using and sharing the Device.
to define a target we needs to add configuration to /etc/tgt/target.conf:
to define a target we need to make its name unique through the whole internet.
• < target (the device name).(the date).(domain/localdomain/ip:name-of-device)
then we need to define the name of device that is defined in that machine:

example:
< target iqn.2016-12.localdomain.localhost:myiscsi >
        backing-store /dev/sde
        initiator-address: 172.24.24.11 # ip address of whom can access device.
</ target >

after configuration we need to enable the tgt daemon.
• systemctl start tgt.service
Centos:
• /etc/init.d/tgtd.service start


to check if the share is available for us we can use 'tgt-admin'
• tgt-admin --show => it prints the information about the target iscsi device if it is available to it.



### 99-824-6 - 204.2 - Adjusting Storage Device Access (iSCSI Network Storage - Initator Configuration) ###
we can find the accessible iscsi devices through network by command:
• iscsiadm  -m discovery -t sendtargets -p 172.24.24.29 => it will send a discovery package in order to find the iscsi device on the end host.

we might also need to restart the iscsi daemon.
• systemctl restart iscsid.service


we might need to change configuration of our mounting if we want to have the dev storage on boot.

we also will be able to use the network iscsi device as similar to all other local dev storage.
for example we will be able to make parition and we can list it via `fdisk -l /dev` or make file system with:
` mkfs -t ext /dev/sde1 `.



### 99-824-7 - 204.2 - Adjusting Storage Device Access (iSCSI Network Storage - Mounting and Using the Device) ###

in order to make the iSCSI network storage to be mounted when OS is boot up, similar to other devices we need to add it to fstab.
` /etc/fstab `

note
> in fstab, because the network iscsi device is known with its name for example: /dev/sda, its going to be called as /dev/sda.

• /dev/sde1     /mnt/iscsi      ext4       _netdev      0 0

we use _netdev instead of defaults because if the network fails it will stop mounting the storage or only consider it as a mount point if the network is available.

you can check it by
• umount /mnt/iscsi
• mount -a => to see if fstab can mount them.



### 99-824-8 - 204.3 - Logical Volume Manager (Physical Volume Group Creation)
 LVM allow us to manage and control our storage volume in much more efficient way.
in this section we are going to focus on Physical Volume Group
Volume Group from Physical Devices means that we can combine the volume of mutiple separated storage devices and used them as a single storage.

firstly we need to create physical volume by using:
• pvcreate /dev/(sdc) => it will define it to LVM as a physical volume
• pvcreate /dev/(sdd) => it will define a physical volume from another device
to confirm that we can use:
• pvdisplay /dev/sdc => it should also print us a PV Name in its table.
• pvdisplay /dev/sdd

• pvdisplay => to list all physical volumes

note:
> we cannot make a physical volume from a partitioned storage device

next we need to create volume group which it means to combine the two devices and make them act as a single storage.



### 99-824-9 - 204.3 - Logical Volume Manager (Volume Group Creation) ###
we can create volume group which can be the sum total of the physical volume that we have created from different storage devices.


####Extent
Extents are the smallest units of space that you can allocate in LVM. Physical extents (PE) and logical extents (LE) has the default size of 4 MiB that you can configure. All extents have the same size.
When you create a logical volume (LV) within a VG, LVM allocates physical extents on the PVs. largest LVMv1 filesystem is 276M but in v2 and later its limit was removed.
the size of extend cannot be changed

to create a volume group with specified extent size and name ` VG0 `
• vgcreate -s 8MB VG0 /dev/sdc /dev/sdd => it will create a volume group with some of two storage devices.

you can confirm the changes with ` vgdisplay ` command.
• vgdisplay VG0 => it will list the detail information about the volume group such as number of current logical volume, physical volume (which is 2 for now). and Physical Extent (PE) size.

now we can extend and add new physical volume to our volume group by:
vgextend /dev/sde => it will add the ` sde ` disk to the logical volume

note:
> in LVMv2 if the physical storage is not paritioned and not created as PV, it will automatically make it as a PV an assign it to VG.

we can see more detail about our VG with:
• vgdisplay VG0 -v => shows more detail about our disks.



### 99-824-10 - 204.3 - Logical Volume Manager (Logical Volume Group Creation) ###
after creating volume group we can map over VG and define how much we want to use from it. to do that we need to create " logical volumes (LG)"

to do that we first need to define the size of our LG, then we need to define the name and indicate from which Volume Group we are going to take it.
• lvcreate -L 500M -n lv0 VG0 => it will create a 500MB size logical volume from the VG0 volume group.

note:
naming convention for logical volume is important, it is recommended to put a number from index 0 at the end of each logical volume. why? because when we are creating logical volume a new link will be created to device called ' md-(number) ' and it will much easier to remember the logical volume order.
to check that, cd to `/dev/` and use:
• ls -al (name of volume group) => it will print all logical volumes in our VG
example: 
• ls -al VG0


### /dev/mapper
all the name conventions for the logical volumes are placed in it and the LVM use it to refer to storage devices.
mapper directory is also used for mount points

mounting a logical volume:
1. to mount that we first need to change its file system time by ` mkfs `
• mkfs -t ext4 /dev/mapper/VG0-mylv0 
or
• mkfs.ext4 /dev/VG0/mylv0

2. when we make a mount point:
• mkdir /mnt/lvm

3. then mount it on the new directory mount point
• mount -t ext4 /dev/mapper/VG0-mylv0 /mnt/lvm

verify that with:
• df -h 

#### lvremove
we can use ` lvremove (namy of logical volume)  ` to remove the logical volume but remember to unmount it first before removing.
• lvremove /dev/VG0/mylv0


#### striping in LVM
as we did till now the LVM will take the first section of our PV -> VG -> LV section and take 500M for instance and write data on it. but we also can define striping (similar to RAID) and distribute the writing of data over multiple storage devices.
for instance instead of writing data on first sectors of the first device, it will distribue the data writing over devices that we indicate:
• lvcreate -i 3 -L 500M -n mystrippedlv0 VG0 => it will stripe the 500M of our logical volume over 3 devices ( if exists)

note:
> striping can cause performance issues and management hassles if is used in very large scale for many small files



### 99-824-11 - 204.3 - Logical Volume Manager (LVM Maintenance - Extending, Reducing and Resizing) ###
before reducing or resizing our logical volume file we first need to monitor our data and size about logical volum.
we can check that by:
• df -h => we can have a survey over the size of our lvm which is mounted.

• vgdisplay => to see the volume groups and their capacities with how much space that is allocated.

#### lvextend
we use lvextend to extend the size of logical volume but remember that after that the ` resize2fs ` or ` growfs ` command in order to write that down on filesystem.
other wise the disk use will show the old value of our logical volume and changes will not apply completely.

• lvextend -L +400M /dev/VG0/mylv0 => we define +400M to indicate adding process and -L to define the size of it.
•  resize2fs /dev/mapper/VG0-mylv0 => to resize the filesystem as well.

check that by:
• df -h 
• vgdisplay

#### how the lvm does that?
by default the xfs filesystem is not possible to be increase or decreases.
lvm does online resizing without damaing filesystem by uses snapshot. snapshot is a concept in lvm that allows to maintain data without being corrupted and increase the size of the filesystem.
note that it doesn't work when we want to reduce the filesystem size unless have unmounted it.


####reducing the size of logical volume:
1.first we need to unmout our logical volume:
• umount /mnt/lvm

2.we do fsck because if we have a dirty filesystem the reducing process will be exacerbated.
• fsck -f /dev/mapper/VG0-mylv0

3. then we change the size. remember that we should define how much size we want it to be in filesystem first and then we commit it with `lvreduce` command.
• resize2fs /dev/mapper/VG0-mylv0 400M
• lvreduce -L -500M /dev/VG0/mylv0

then mount it again.

mount -t ext4 /dev/mapper/VG0-mylv0 /mnt/lvm/



### 99-824-12 - 204.3 - Logical Volume Manager (LVM Maintenance - Snapshots) ###
snapshot allows us to take a exact same backup file from a logical volume at the time of that LV. however you should pay attention that the volume group that your LV presents also needs to have enough space for a snapshot.
• vgdisplay VG0 => to see the VG0 volume group free space.

• lvcreate -L 500M -s -n mysnap0 /dev/VG0/mylv0 => it will take a snapshot from the mylv0 LV which is also around 500M.

then we can mount it and examine the logical volume by
• mkdir /mnt/snapped-mylv0
• mount -o ro /dev/mapper/VG0-mysnap0 /mnt/snapped-mylv0 => we mount as as read-only condition.

then we can remount it instead of mylv0 in order of data lost.



### 99-825-1 - 205.1 - Basic Networking Configuration (Interfaces - ifconfig) ###
we can see the network interface configuration on our linux OS by issuing:
• ifconfig => it will list all Configured network interfaces

however, if a network is not configured or shutdown we can list all interfaces that are detected with:
• ifconfig -a => it will list all interfaces regardless of their configuration and status.

ifconfig is also used to Temporary config network setting on our interfaces:

• ifconfig eth1 192.168.1.120 netmask 255.255.255.0 broadcast 192.168.1.255
ifconfig (interface) netmask (netmask IP) broadcast (broadcast IP)

to verify that use:
• ifconfig eth1

to turn off and on a interface use:
• ifconfig eth1 down/up

note:
> changes are not going to be carried after reboot

for debuging we can turn on ` promiscuous mode ` for our interface. it will listen to all packets that are being broadcast and will let them into OS for dumping.
• ifconfig eth1 promisc
• ifconfig eth1 -promisc => to turn it off



### 99-825-2 - 205.1 - Basic Networking Configuration (Routing - arp) ###
arp (address resolution protocol) is used to find the media access control address of a network neighbour for a  given  IPv4  Address. arp command manipulates or displays the kernel's IPv4 network neighbour cache. It can add entries to the table, delete one or display the current content.

commands:
• arp => arp command alone will list all IP address with HWtype (hardware Type) and the WHaddress (Hardware Address) that is correspond to sending packets to that destination.

• arp -i (interface name): is used to only show the arp request that are passed through defined interface

• arp -d (ip address) : to delete an arp from table

• arp -v: gives more information about arp table (is the default flag)



### 99-825-3 - 205.2 - Advanced Network Configuration and Troubleshooting (Viewing Network Activity - netstat, lsof and nc) ###
#### netstat
netstat is used to print  information  about the Linux networking subsystem.  The type of information printed is controlled by the first argument.
for example:
• netstat -s => it prints a summary of packets in different transfering protocols.

• netstat -i => shows network packets related to each interface

• netstat -r => shows the routing table

• netstat -au or -at => to print a summary of TCP or UDP traffic.

• netstat -eee => to make a full verbose mode for netstat traffic. ( it is the default)

the useful command for netstat is:
• netstart -tulpn => it prints listening udp and tcp services with their name.


#### lsof 
lists all open files and the process of network activity
• lsof -n => lists the files without name resolver so the IP will be shown (useful for when name resolver doesn't work or we want to see the IP)


#### nc (net cat)
nc can open TCP connections,send UDP packets, listen on arbitrary TCP and UDP ports, do port scanning, and deal with both IPv4 and IPv6.  Unlike telnet(1), nc scripts nicely, and separates error messages onto standard error instead of sending them to standard output, as telnet(1) does with some.
use cases:
network daemon testing
SOCKS or HTTP proxy cmmand for ssh
shell-script based HTTP clients and server.

to use netcat:
on the server we can use:
• nc -l -k 80 => it will listen to port 80 and won't be terminated even if the connection is off.

and on the client, we can connect to it with:
• nc 192.168.1.110 80 => it will connect to port 80 of the end host IP

* then by writing anything in the client terminal, the end host will print that as well.



### 99-825-4 - 205.3 - Troubleshooting Network Issues (Troubleshooting and Configuring Network Interfaces) ###
the network configuration can be vary depend on different distros: for instance:
in Rocky9 the configuraion exist in /etc/NetworkManager directory
you can examine it in:
/etc/network-scripts/readme-ifcfg-rh.txt

In CentOS Distro we can create a file in /etc/sysconfig/network-scripts/ with the name: ` vim ifcfg-inet1 `
we can define configuration as such:
DEVICE=eth1
IPADDR=192.168.1.110
NETMASK=255.255.255.0
BROADCAST=192.168.1.255
ONBOOT=yes
BOOTPROTO=none

(options:)
UUID= 3145sdfwer => we can use UUID for our interface

after changes, the network service needs to be restarted



### 99-826-1 - 206.1 Make and Install Programs from Source (Unpack, Configure, Compile and Install) ###
for installing packages on Linux OS, depends on different Distros their are many ways to install a package.
for instance we can use curl or wget to download packages from web pages.

they are two type of packages or group installations:
in CentOs we use for instance:
yum groupinstall "Development Tools" => it will install all packages and dependencies related to Development Tools.

in Ubuntu and Debian Base Distros:
build-essentials

most of the file that are being got with 'wget' are mostly in tar archive format.

#### make makefile

#### compile and installation
(not completed)



### 99-826-2 - 206.2 Backup Operation (Standard Tools - dd, tar and rsync) ###

#### dd
dd is used to copy the whole block storage device to somewhere else it does that by defining input file and output file with options.

for instance we are going to copy a whole mounted file system to another file system.
to do that first we need to unmount the input file system in order to safely copy everything and stop being things to be overwritten.
• umount /mnt/mounted1

then we can dd all the device storage to another device storage block.
• dd if=/dev/sdb1 of=/dev/sdc2 => it will copy all the block of sdb1 to sdc2 but be aware that the output device should also have enough space.

when we can mount the again:
• mount -t ext4 /dev/sdb1 /mnt/mounted1
• mount -t ext4 /dev/sdc1 /mnt/mounted2

by using ` df -h ` we should have two identical file systems.
or we use ` du =sh ` inside the filesystems to see their occupied capacity.


we also can use dd to write on an .iso file or .img file 
• dd if=/dev/sdb1 of=/mnt/fileImage.img => it will write all the sdb1 onto the fileImage file to take an image.
• dd if=/dev/sr0 of=/mnt/file.iso => to write an iso file a a CD or DVD.

#### tar (tape archive)
is an archive utility that is used make archive from files and also to compress or decompress files. the tar was firstly developed in order to archive file in tape devices such as /nst and /st.
the common commands for tar is:

##### for creating a compressed tar archive:
• tar cvzf mybackup.tar.gz /mnt/backupfile => it will create a tar file with "-cf " and will make it compresssed by "-z". "-v" is used for making it verbose. then mybackup.tar.gz is the name that we pick for our file. and the source where we want to take tar file.

##### we can examine or see inside the tar file with command:
• tar tfv => it will print the content of tar fil

##### for extracting file from an archive file
• tar -xvzf mybackupfile.tar.gz /destination-path => it will extract the compressed tar file.

#### mt (magnetic tape) 
mt is an old utility to manipulate magnetic tape drivers and is used to archive file on magnetic tape devices.


#### rsync
rsync is a tool for taking backup from remote or local files and also sync changes that happen to remote or local file and take copy of what has been altered.

to archive and copy a in a local device to somewhere else we do:
• rsync -avz /mnt/lvm/backup /mnt/castel/synced/ => it will take an archive file from /lvm/backup to /castel/synced


#### remote backup and syncing
we can also take backup from a remote host directory and also sync changes that happen on the remote device.
the rsync do that by creating an incrimental file list that looks for changes on remote device file and if modification happens over that directory, it will add it in the original device as well:

• rsync -avz mohammadreza@192.168.1.120:/home/monitoring/*.conf  /home/sandbox/Monitoringbackups => it will take all the files that have conf in their extension and copy it in to /home/sandbox/Monitoringbackups

we can use "-L,-l" or "-h, -H" to copy soft-links or hard-links too.

to copy files to a remote file we also use:
• rsync -avz /home/sandbox/Monitoringbackups/*.conf mohammadreza@192.168.1.120:/home/monitoring/



### 99-826-3 - 206.3 Notify Users on System-Related Issues (Broadcast Messages with issue, wall and motd) ###
 
ssh login banner
it is a good habit to configure a security banners for ssh logins
there are two ways to display banner message. first is issue.net and second is using MOTD
issue.net: display banner before password prompt
motd: display banner after the user login process.

1. edit the issue.net file in configuration directory.
• cat or vim /etc/issue.net

2. then inside /etc/ssh/sshd_config file we edit Banner /etc/issue.net
• Banner /etc/issue.net

3. restart the ssh service
• systemctl restart ssh.service.

#### motd
motd on some common latest distros is blank and needs to be configured. on some distros the MOTD exists in /etc/update-motd/
display SSH warning with MOTD
• vim /etc/motd => editting the MOTD file 

wall
wall displays a message or the content of a file to other users terminal but it is not active in debian base systems.
• cat message.txt | wall => it will show message.txt with wall message.

note:
> wall command is not permitted to be executed by every user and it needs privilege changes.



### 111-036-1 - 207.1 - Basic DNS Server Configuration (DNS Client Configuration and Terms) ###

there are two primary types of DNS with different sub-types.
1. first one is the cache server DNS. it saves the query of DNS request which makes better performance and prevent the need to query over public internet each time for a name server.
2. the second is the Name server itself which provides the Domain Name Resolver Functionality.

in Linux Distro Client Perspective we have a ` /etc/resolv.conf ` file which is used to declare which Nameserver should be used. or by defining a `search` parameter we define what domain name should be set for different searches:
nameserver: it tells the computer to use each ip as nameserver for example: nameserver 4.2.2.4
domain: it tells the computer which domains should system look for for specific subdomain or CNames: domain techguy.net

search: it informs computer what it should search if the name is not completed for example: search techguy.net company.net if these words are half written.
    - instance: if we define " search: techguy.net " and then nslookup for www, it will query for www.techguy.net unless we define the whole domain name.
note:
> if your system has multiple interfaces and those interfaces are in multiple DNS zones you can define multiple domain in a domain line but you cannot define multiple domain in search line

note:
> /etc/resolve.conf is manipulated by systemd-resolver, so some configuration might alter after changes on resolve.conf file.

DNS structure
1. Root
2. Top Level Domains (TLDs): .org, .com, .de, .uk, .
3. Second Level Domain (SLD): google, wikipedia, mocrosoft, 056
4. Third Level Domain (subdomains): www, technet, plus, target, ftp
5. A fully qualified domain name (FQDN): is a complete, unambiguous domain name that specifies the exact location of network resources, such as servers, websites, or services, on the Internet
6. DNS name of the computer

Zone File:
DNS is consist of resource Records such as A Records, Domain Names which are stored in Zone files.

forward lookup: forward lookup returns the IP address when supplied with a domain name. a forward lookup zone can contain other recrods such as MX, CName and etc.
Reverse look up: reverse lookup zone is used to lookup the domain name when supplied with an IP address.

we use nslookup for testing our DNS queries and the nslookup is a utility from ` bind-utils `



### 111-936-2 - 207.1 - Basic DNS Server Configuration (BIND Installation - Caching Name Server) ###
DNS Service Providers are:
BIND9 ( which will be used)
DNS Mask ( powerful forwarding DNS configuration)
powerDNS
DJB-DNS

to begin we need to install packages for DNS service:
• apt install bind9 bind9-utils

the configuration file for DNS Bind in debian (Ubuntu) is located in  ` /etc/bind/ ` and in bind9 the configuration files are separated.

an step for configuring the DNS Service.
#### listening port
we can define listening port and listening interface for our OS:
for example by defining the:
```shell
 options {
 listen-port port 53 { 127.0.0.1; 192.168.1.110 }; # we are defined for instance the IP address of only one of our interfaces and the localhost.
 allow-query { localhost, !172.24.24.27 , 192.168.1.100} # in this case ! means to not allow the specified IP to query for DNS
 
 dnssec-enable: yes
 dnssec-validation: yes # these two are for validating request for DNS query 
 
 };
 
 ```
 in the case above we define that the IPv4 DNS server should listen on port 53 (default) and on IP of local and one of its interfaces. by that we can define for instance zones.

the service resposible for handing the DNS configuration of BIND9 is ` named.service `
• systemctl status named.service



### 111-936-3 - 207.1 - Basic DNS Server Configuration (BIND Service Start and rndc Command) ###

for changes such as dumping, flushing, reloading configuration and etc on our DNS configuration we use ` rndc `
rndc (Remote Name Daemon Control) is the name server control utiliy. rndc communicates with the name server over a TCP connection, sending commands authenticated with digital signatures. it also reads the configuration file in order to find out how to contact with name server.
rndc.key file exists in:
ubuntu: /etc/bind/rndc.key => it hold the security token to work with nameserver.

command examples:
• rndc reload => it will reload the configuration to apply changes.

in order to regenerate an rndc key file for security or practices purposes first we need to (scenario and not yet implemented):
1. stop the ` named.service ` 
• systemctl stop named.service 

2. then use urandom utility to create random seed to feed into our rndc.key file
• rndc-confgen -r /dev/urandom -a > /etc/bind/rndc.conf => it will create random seed for rndc.key and also adds it to rndc.conf file
• rndc flushname (domain name) => flush all queries related to that domain name
• rndc flush => flush all query cache

3. then we need to add the key object in rndc.conf to named.conf file 

4. also for security we need to take the permission of read access off from the rndc.conf and key file. by changing the group with `chgrp named /file-name `
and change the permission with ` chmod 640 /file-name`

5. finaly restart the named service and it should not throw any error.

note:
> after the changes we might get warning for using rndc commands and thats because we also have the same key file in the configuration directory.
> by removing the rndc.key the warning should also be gone.


#### dig
dig is a flexible tool for interrogating DNS name servers.It performs DNS lookups and displays the answers  that  are  returned  from  the  name server(s) that were queried.
Unless it is told to query a specific name server, dig tries each of the servers listed in /etc/resolv.conf. If no usable  server  addresses  are found, dig sends the query to the local host.
thus we can define the namesever for dig to ask a domain name resolution fro that.
• dig @localhost google.com => it will ask localhost to interrogate google.com
• dig @1.1.1.1 cnn.com 


#### host
host is a simple utility for performing DNS lookups. It is normally used to convert names to IP addresses and vice versa.
• host cnn.com @localhost 



### 111-936-4 - 207.2 - Create and Maintain DNS Zones (Configuring for Zones) ###

Record Types (detailed)
##### SOA - Start of Authority
Defines authoritative information about a zone which contains:
- Name server: Domain of the master server 
- Email: DNS admin email address (where "." is used instead of @ between the name and domain name)
- Serial number: a number that indicates whether a zone needs to be updated to a slave, anytime a change is made to a zone file the number must be incremented to show that the serial number is changed and slave will update itself by comparing that number.
- Refresh: determines the frequency a slave server queires the master to determine if updates are required (zone transfer is needed).
- Retry: how long a slave wait to retry a master query for update
- Expiry: when the slave stops responding to DNS query requests if the Master continues to be unavailable (the zone becomes in stale mode and not be used)
- Minimum: length of time to cache responses ( for instance to cache the query that the Name server does NOT have responsibility for that for period of time)

##### Address Type (A record)
Defines a direct name to address translation. for example ` prod.example.com IN A 192.168.1.30 `
Defines the prod.example.com server to the IP of 192.168.1.30 if queried.
Can be given relaive to the current domain such as just "prod" or as a FQDN (Fully Qualified Domain Name)

##### Canonical Name (CName)
allows to define a host with more than one name/role in your domain for example: your example.com might have www. mail. and dev. in its CName.
logs.example.com and mail.example.com and www.example.com
this indicates that the name logs.example.com translate to the name mail.example.com and thus to the IP 192.168.1.30

##### Name Server (NS)
Every domain can have one or more name servers, they are define as NS records.
Although the master name server is also defined in the SOA record, that server must have a fully entry in the NS record definition.
example: `@  IN  NS  named.example.com`

##### Mail Exchange
Sending email services (MTA: Mail Transfer Agents) have to be able to figure out which host handles inbound email for the zone/domain. we can create one or more MX records for that.
example:
` @   IN  MX  10  servicemail.example.com `
` @   IN  MX  20  backupmail.example.com `
note:
> the number indicate the priority they should be tried for mail delivery.the number can be same for load balancing configuration

##### Pointer Records (PTR)
This Record is used in reverse lookup zone files so that that Ip can be translated into the name
note:
> not all records have to have a reverse lookup PTR record so be aware of that.
example:
`101.0.1.10.in-addr.arpa.    IN  PTR     www.example.com.(FUll record)`
` 101       IN      PTR     www.example.com. (shorter record) `


we also have other record types but the above are the most common ones.



### 111-936-6 - 207.2 - Create and Maintain DNS Zones (Finalize _etc_named.conf for Master DNS Server) ###
because we are going to run a Name server which will going to behave as a master Name server, we need to limit others to access.

##### disabling update from other hosts:
by adding attributes to the zone object in named.conf file we can define the zone update allowance:
```shell
zone "mohammaddomain.com" {
    type master;
    file "fwd.mohammaddomain.com.db;
    allow-update {none;};
};

zone "192.168.61.in-addr.arpa"{
    type master;
    file "44.31.172.db";
    allow-upate {none; };
}

```


### 111-936-7 - 207.2 - Create and Maintain DNS Zones (Create Forward and Reverse Zone Files and Testing the Configuration) ###

in bind9 (CentOS or Rocky in this practice) the zone files are located in ` /var/named ` directory
the /var/named directory is a none-root chroot jail directory which only sudo permission is allowed to have access in it by default

##### named.ca
named.ca contains list of all the root servers that our DNS service is using them.


#### Creating a Zone
-1. to determine a zone we first need to make two config fields in `/etc/named.conf` these two added configuration will determine the forwarder and reverse DNS in our zone. so in "/etc/named.conf":

``` sh
zone "nov.tech" {
        type master;
        file "fwd.nov.tech.db";
        allow-update { none; };
};

zone "172.24.24.in-addr.arpa"{
        type master;
        file "172.24.24.db";
        allow-update {none ; };
};
```
in the script above the ``no.tech`` is the forwarder and we have defined its file name.
the `172.24.24.in-addr.arpa` is the reverse proxy which we have in this case define a range of IP that is the range of IP that is going to be resolved in our zone.


-2. then we need to create the database files for newly created zones in `/var/named/`
<domain.name.> IN SOA <hostname.domain.name.>     <mailbox.domain.name>
                                <serial-number>
                                <refresh>
                                <retry>
                                <expire>
                                <minimum-ttl>
• domain name: the name of the domain which the SOA belongs. the @ can be used so, the namesever will fill it automatically. note that "." is important at the end of each domain name which define the root
• IN: the class of the  DNS record. IN stands for Internet.
• SOA: the type of the DNS record
• serial: number is an arbitary number but forward and reverse zone serial numbers should be the same. if the secondary server's serial number is lower, it indicate that the secondary server's record are out of date and requires zone transfer from primary server.
• refresh: defined for slave how often should it refresh for new changes.
• retry: the number of times that the slave will try to connect when master server is unavailable until it call it as slate. if a refresh attempt fails a secondary server will retry after.
• expire: the secondary server will stop serving the zone after the period specified in the expire field  expires and this expiration is caused when retry and refresh are both failed.
• minimum-ttl: Time to live for every record in the zone. when changes are made to a zone, the default is often set from ten minutes or less.

example
file `/var/named/fwd.nov.tech.db`
note:
> we use `;` in order to make a comment on the lines.
```sh
$TTL 86400
@ IN SOA named.nov.tech. root.nov.tech. (
                10030   ;Serial
                3600    ;Refresh
                1800    ;Retry
                604800  ;Expire
                86400   ;Minimum-TTL
)
; Name Server
@               IN      NS      named.nov.tech.
; A Records Lists
named           IN      A       172.24.24.29
zabbix          IN      A       172.24.24.12
mailproduction  IN      A       172.24.24.14
proxyserver     IN      A       172.24.24.13
; Canonical Name / Alias
dns             IN      CNAME   named.nov.tech.
; Mail Exchange Records
@               IN      MX      10      mail.nov.tech.
@               IN      MX      20      mailbkp.nov.tech. ;this one will be used as backup or load balancer.

```

then we need to configure the `/var/named/172.24.24.db` for the PTR records:

```sh
$TTL 86400
@       IN      SOA     named.nov.tech. root.nov.tech. (
                        10030   ;Serial
                        3600    ;Refresh
                        1800    ;Retry
                        604800  ;Expire
                        86400   ;Minimum-TTL
)
; Name Server
@       IN      NS      named.nov.tech.
; Poniter Records
12      IN      PTR     zabbix.nov.tech.
13      IN      PTR     proxyserver.nov.tech.
29      IN      PTR     named.nov.tech
```

In PTR field we use the last IP octets to to define the PTR record because we have already indicated the range of IP in `named.conf` file.

to verify the if we have error we do:
• named-checkconf => to check the configuration file

• named-checkzone nov.tech fwd.nov.tech.db => to check the forwarder file
` named-checkzone <zone-name> <zone-file> `
• named-checkzone 172.24.24.in-addr.arpa 172.24.24.db

then we need to restart the named.service.
• systemctl restart named.service

test the DNS service by:
• dig @localhost named.nov.tech => using @localhost to indicate the NS
• nslookup dns.nov.tech localhost => to lookup the dns Canonical name with localhost NS\

DNS service in here is only responsible if the Domain and IPs are translatable.



### 111-936-8 - 207.3 - Securing a DNS Server (Split DNS Configuration for Security) ###
What is Split DNS Configuration:
The abliity to provide both private (internal) and public (external) DNS queries using servers in both private and public security zone.
for example you have some services on the same domain that are intended only for private use (accounting and HR) so we deploy a single (master/slave) DNS Server Configuration in each zone.
Commonly you will see the Private DNS Master setup use the Public DNS Master as a caching or forard DNS Server for internal Clients.



### 111-936-9 - 207.3 - Securing a DNS Server (Running BIND in a Chroot Jail) ###

running DNS on chroot jail
Chroot jail is used to create a limited sandbox for a process to run in. This means a process cannot maliciously change data outside the prescribed directory tree. Another use for chroot jails is as a substitute for virtual machines

to run our Named Service in Chroot first we need to stop the service by ` systemctl stop named.service `

then we need to change configuration on named file in sysconfig to indicate that the configuration and rest of the file's location which will be in `/chroot/`
• vim /etc/sysconfig/named
add the below line at the end of the file
• -t /chroot/named/ => to start in chroot direcotry.

the prepare the named directory in /chroot
• /named/ as root
• /named/etc for configurations
• /named/dev for specific devices such as random or null file
• /named/var/named the primary location of all zone files
• /named/var/run the location of process data is stored.

then we cp important files to root jail such as:
• cp /etc/named.conf /chroot/named/etc
• cp /etc/localtime /chroot/named/etc
• cp -rf /var/named/* /chroot/named/var/named

then we will change ownership of the file solely to the named service user.
• chown named:named -R /chroot/named

we also add the devices that will be needed by named service.
• mknod /chroot/named/var/dev c 1 8
• mknod /chroot/named/var/dev c 1 3 
• chmod 666 /chroot/named/dev/*

finally start the service
• systemctl start named.

very that with:
• ps aux | grep named
• dig @localhost named.nov.tec



### 111-936-10 - 207.3 - Securing a DNS Server (DNS Security Tools - Discussion, Keys and Signing a Zone File) ###

DNS service has Other Security Tools that allows use to confirm that the zones , or qeuries are coming from trusted sources
by default some of Security Tools are added to DNS packages. these tools are for example:
dnssec-keygen => which can generate public and private key which can be used for verification process
dnssec-signzoe => to create a secure zone for perticular domains.

##### What is TSIG (Transaction signature) in DNS?
referred to as Secret Key Transaction Authentication, ensures that domain name service (DNS) packets originate from an authorized sender by using shared secret keys and one-way hashing to add a cryptographic signature to the DNS packets.

##### dnnsec-keygen
-a => to define the type of encryption
-b => size of the key in bytes between 1 to 4096 (it also depends on the type of encryption as well)
-n => to define the nametype for example ZONE or HOST or ENTITY
-f => to set specific flag in the filed of the KEY/DNSKEY record. (which is KSK)
for example:
• dnnsec-keygen -a RSASHA256 -b 2048 -n ZONE -f KSK nov.tech

after generating the dnssec public and private ke we need to use `dnssec-signzone` to use the generate pair keys in order to sign our zones. public key will sign them and private key with uncrypt the data.

in the /var/named directory where our zone files are kept we do:
• dnssec-signzone -o nov.tech -S fwd.nov.tech.db => it will sign the zone file and create a `.signed` file for that.

if you can the fwd.nov.tech.db.signed file it will now contain the encryption data.

finally we need to change the `/etc/named.conf` and change the file path for our zone for which will be 
``` sh
zone "nov.tech" {
        type master;
        file "fwd.nov.tech.db.signed";
        allow-update { none; };
};
```


######  #######



### 111-937-12 - 208.4 - Implementing Nginx as a Web Server and a Reverse Proxy (Nginx - Installation and Configuration as Web  ###

Nginx can outperform in heavy loads and traffics among most of other web servers. it also can be used for reverse proxy as well.
Nginx can be used for load balancing, website management, authentication and can support various protocols.

to use Nginx, it first needs to be installed.
• apt install nginx 
• yum install nginx

the default configuration for nginx is located in:
` /etc/nginx `

Basic configuration for http server in `nginx.conf` file:


