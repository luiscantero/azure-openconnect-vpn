# OpenConnect VPN server on Azure with Let's Encrypt certificate
## Description
- Script to setup an OpenConnect (ocserv) VPN server on a Linux VM running on Azure
- Tested on Ubuntu 18.04 and Raspberry PI (Raspbian Stretch)
-  Features:
  - Setup by executing one line
  - Robust SSL-based VPN that works well with firewalls and proxies
  - Fast clients for Desktop and Mobile devices
  - Auto-renewing Let's Encrypt certificate

## Steps
1. Create an `Ubuntu Linux VM` on Azure
- Select `password authentication`
- Smallest instance (~7$/month) is enough for normal workload
- Configure `DNS name` (FQDN)

2. Open Azure firewall
- `Port 80 HTTP (TCP)` so that certification server can communicate with Let's Encrypt certbot
- `Port 443 HTTPS (TCP/UDP=Any)` for VPN

3. SSH to server
- `ssh <USERNAME>@<SERVER_NAME>.cloudapp.azure.com`

4. Create installation script
- `touch installoc.sh && chmod 755 installoc.sh && nano installoc.sh`
- Paste script, save (Ctrl+O) and close (Ctrl+X) file
- Run: `./installoc.sh <FQDN> <EMAIL>`
- Example: `./installoc.sh EXAMPLE.eastus.cloudapp.azure.com luis@example.com`

5. Clients
- Windows
  - https://github.com/openconnect/openconnect-gui
- Linux
  - Install: `sudo apt install openconnect -y`
  - Connect: `sudo openconnect -b EXAMPLE.eastus.cloudapp.azure.com`

6. Advanced
- Authentication using Ubuntu system accounts supported by default: `pam[gid-min=1000]`
  - Add account: `sudo adduser <USERNAME>`
- Authentication using password file can be used by editing the script: `plain[passwd=/etc/ocserv/ocpasswd]`
  - Add account: `sudo ocpasswd -c /etc/ocserv/ocpasswd <USERNAME>`
- Authentication methods utilizing passwords cannot be combined (e.g., the plain, pam or radius).

- Enable LAN access
  - Enable Proxy ARP: `sudo nano /etc/sysctl.conf`
  - `net/ipv4/conf/all/proxy_arp=1 # Enable Proxy ARP on all interfaces.`
  - `sudo sysctl -p`
  - Configure DNS and IP range: `sudo nano /etc/ocserv/ocserv.conf`
  - `dns = 192.168.178.1 # Router gateway.`
  - `ipv4-network = 192.168.178.201/27 # Outside of router DHCP range.`
  - `sudo systemctl restart ocserv`

### License
[MIT](http://opensource.org/licenses/MIT)

## Reference
- [OpenConnect VPN Project](https://github.com/openconnect/)
- [OpenConnect on Wikipedia](https://en.wikipedia.org/wiki/OpenConnect)
- [Pseudo-Bridge setup with Proxy ARP](https://github.com/openconnect/recipes/blob/master/ocserv-pseudo-bridge.md)