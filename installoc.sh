# Requirements:
# 1. Open firewall
# 1.1. Port 80 HTTP (TCP) so that certification server can communicate with certbot
# 1.2. Port 443 HTTPS (TCP/UDP) for VPN
# 2. Create script:
# touch installoc.sh && chmod 755 installoc.sh && nano installoc.sh
# 3. Clients
# 3.1. Windows: https://github.com/openconnect/openconnect-gui
# 3.2. Linux
# 3.2.1. Install: sudo apt install openconnect -y
# 3.2.2. Connect: sudo openconnect -b <SERVER>

if [ -z "$1" ] || [ -z "$2" ]
  then
    echo "Usage: $0 <FQDN> <EMAIL>"
    exit 1
fi

set -e # Exit if error.

echo "1/7. Install OpenConnect VPN server (ocserv) and Let's Encrypt client (certbot) ..."
sudo apt install ocserv -y
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:certbot/certbot -y
sudo apt update
sudo apt install certbot -y

echo "2/7. Request Let's Encrypt certificate ..."
sudo certbot certonly --standalone --preferred-challenges http --agree-tos -n --email $2 -d $1

echo "3/7. Auto-renew certificate daily ..."
# Auto update OS at 7 AM every Monday.
(crontab -l 2>/dev/null; echo "0 7 * * 1 apt-get update && sudo apt-get upgrade -y") | crontab -
(crontab -l 2>/dev/null; echo "@daily certbot renew --quiet && systemctl restart ocserv") | crontab -

echo "4/7. OpenConnect VPN server config ..."
# Use Let's Encrypt certificate.
sudo sed -i "s/\(^server-cert *= *\).*/\1\/etc\/letsencrypt\/live\/$1\/fullchain.pem/" /etc/ocserv/ocserv.conf
sudo sed -i "s/\(^server-key *= *\).*/\1\/etc\/letsencrypt\/live\/$1\/privkey.pem/" /etc/ocserv/ocserv.conf

#-> #auth = "pam[gid-min=1000]"
#sudo sed -i "s/\(^auth *= \"pam\[*\)/#\1/" /etc/ocserv/ocserv.conf
#-> auth = "plain[passwd=/etc/ocserv/ocpasswd]"
#sudo sed -i "s/^#\(auth *= \"plain\[passwd=\)\.\/sample.passwd\]\"\(.*\)/\1\/etc\/ocserv\/ocpasswd\]\"/" /etc/ocserv/ocserv.conf

#-> try-mtu-discovery = true
sudo sed -i "s/\(^try-mtu-discovery *= *\).*/\1true/" /etc/ocserv/ocserv.conf
#-> dns = 8.8.8.8 # Google DNS.
sudo sed -i "s/\(^dns *= *\).*/\18.8.8.8/" /etc/ocserv/ocserv.conf
#-> #route
sudo sed -i "s/\(^route *= *\)\(.*\)/#\1\2/" /etc/ocserv/ocserv.conf
#-> #no-route
sudo sed -i "s/\(^no-route *= *\)\(.*\)/#\1\2/" /etc/ocserv/ocserv.conf

sudo systemctl restart ocserv

echo "5/7. Enable IP forwarding ..."
#-> net.ipv4.ip_forward=1
sudo sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
sudo sysctl -p

echo "6/7. Configure IP masquerading ..."
eth0="$(ip addr | grep BROADCAST | cut -d ':' -f 2 | tr -d '[:space:]')"
sudo iptables -t nat -A POSTROUTING -o $eth0 -j MASQUERADE

echo "7/7. Persist IPTable configuration ..."
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
sudo apt-get install iptables-persistent -y