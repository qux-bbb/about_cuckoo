net_card="ens32"
CWD=/home/hello/.cuckoo

# set iptables
# clear iptables
sudo iptables -t nat -F
sudo iptables -F

sudo iptables -t nat -A POSTROUTING -o $net_card -s 192.168.56.0/24 -j MASQUERADE

# Default drop.
sudo iptables -P FORWARD DROP

# Existing connections.
sudo iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

# Drop connections from vboxnet to local internet.
sudo iptables -A FORWARD -s 192.168.56.0/24 -d 172.0.0.0/8 -j DROP
sudo iptables -A FORWARD -s 192.168.56.0/24 -d 192.168.0.0/16 -j DROP

# Accept connections from vboxnet to the whole internet.
sudo iptables -A FORWARD -s 192.168.56.0/24 -j ACCEPT

# Internal traffic.
# sudo iptables -A FORWARD -s 192.168.56.0/24 -d 192.168.56.0/24 -j ACCEPT

# Log stuff that reaches this point (could be noisy).
sudo iptables -A FORWARD -j LOG


# set ip forward
echo 1 | sudo tee -a /proc/sys/net/ipv4/ip_forward
sudo sysctl -w net.ipv4.ip_forward=1


# configure vboxnet0
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0

# start cuckoo-web and cuckoo-api
sudo service uwsgi start cuckoo-web
sudo service uwsgi start cuckoo-api
sudo service nginx start

# start other cuckoo things
supervisord -c ${CWD}/supervisord.conf