## what are the other **name resolver** services in linux distros. other than netplan or etc/resolve.conf
the primary is `systemd-resolved` and **Name Sevice Switch (NSS)**, configured through `/etc/nsswitch.conf`.

### 1.`systemd-resolved`
This is the system service provided by systemd on many modern distributions (like Ubuntu, Fedora, Debian, etc.) that handles network name resolution. It often acts as a local DNS cache and forwarding stub resolver.
it is A dedicated service (`systemd-resolved.service`) that provides DNS, DNSSEC, Multicast DNS (mDNS), and Link-Local Multicast Name Resolution (LLMNR) to local applications. </br>
On systems using `systemd-resolved`, the file `/etc/resolv.conf` is frequently a symlink to a file managed by the service (often `/run/systemd/resolve/stub-resolv.conf` or `/run/systemd/resolve/resolv.conf`). This symlink points all applications that still rely on the old file to the local `systemd-resolved` stub resolver, which listens on a local IP like `127.0.0.53` </br>

#### Managing Utilities:
You can inspect and manage the service's state and configuration in real-time using the `resolvectl` command.
`resolvectl status`


### 2.`dnsmasq` or `unbound`
These are often used in environments where more control over DNS caching, forwarding, or local DNS service is needed, though they aren't default system resolvers in the same sense as `systemd-resolved`.

- `dnsmasq`: A lightweight, easy-to-configure DNS forwarder and DHCP server. It can serve as a DNS cache for a single machine or a small network.
- `unbound`: A validating, recursive, and caching DNS resolver, often used for more advanced or security-focused configurations.


### 3. The Name Service Switch (`/etc/nsswitch.conf`)
This file is arguably the most crucial file for defining the order in which your system's C library (glibc) will look up various types of information, including hostnames. </br>
it is a configuration file for the Name Service Switch library, which determines the sources and order for obtaining system information like passwords, groups, and, critically, hosts. </br>


### 4.`/etc/hosts`
Although very simple, it's the first resolver mechanism consulted on most Linux systems due to the standard configuration in `/etc/nsswitch.conf`. </br>
It is a static file that maps IP addresses to hostnames. It provides a basic, local, and extremely fast way to resolve names without needing to query a DNS server. This is often used for:
- mapping `127.0.0.1` to `localhost`. 
- definining local network hostnames in small labs.
- blocking unwanted domain by poiniting them to `127.0.0.1` basic (ad/malware blocking)


### 5.Network Manager Configuration (`NetworkManager`, `systemd-networkd`)
While Netplan is one way to configure the network, other network management daemons also directly control DNS settings, which then feed into `systemd-resolved` or `/etc/resolv.conf`.
- **NetworkManager**: Configuration files are usually in `/etc/NetworkManager/system-connections/` or managed via nmcli. These settings override global configurations and are specific to a network connection (Wi-Fi, Ethernet, VPN).

- `systemd-networkd`: Configuration files are in `/etc/systemd/network/` (e.g., `50-static.network`). These files contain a `[Network]` section where you can specify `DNS=` and `Domains=` settings per interface.



## Jumbo Frames and Maximum Transmission Unit (MTU)
**Jumbo Frames are Ethernet frames** that have a payload size larger than the standard Maximum Transmission Unit (**MTU**) of **1,500 bytes**. The most common size used for Jumbo Frames is **9,000 bytes**, although different limits exist depending on the vendor and implementation. </br>

Jumbo Frames are used primarily in high-speed networks (like Gigabit Ethernet and faster) and environments where large amounts of data are transferred, such as data centers, **Storage Area Networks (SANs)**, or backup/replication processes

### Benefits of Jumbo Frames:
- **Reduced Overhead**: Since one large frame can carry the data of multiple standard frames, the number of required frame headers and trailers is reduced. </br>
- **Reduced CPU Utilization**: Fewer, larger frames mean the network devices (NICs, switches, CPU) have to process fewer packets, reducing the processing overhead and freeing up CPU cycles. </br>
- **Increased Throughput/Efficiency**: Sending more data per frame can improve network efficiency and overall throughput for large transfers. </br>

**Caution:** For Jumbo Frames to work, all devices along the communication path—including the sender, receiver, and all intermediate network devices (switches, routers)—must be configured to support the same larger MTU size




