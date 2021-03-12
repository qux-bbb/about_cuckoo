net_card="wlp5s0"

# clear iptables
sudo iptables -t nat -F
sudo iptables -F

sudo iptables -t nat -A POSTROUTING -o $net_card -s 192.168.56.0/24 -j MASQUERADE

# Default drop.
sudo iptables -P FORWARD DROP

# Existing connections.
sudo iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

# Accept connections from vboxnet to the whole internet.
sudo iptables -A FORWARD -s 192.168.56.0/24 -j ACCEPT

# Internal traffic.
# sudo iptables -A FORWARD -s 192.168.56.0/24 -d 192.168.56.0/24 -j ACCEPT

# Log stuff that reaches this point (could be noisy).
sudo iptables -A FORWARD -j LOG


# set ip forward
echo 1 | sudo tee -a /proc/sys/net/ipv4/ip_forward
sudo sysctl -w net.ipv4.ip_forward=1