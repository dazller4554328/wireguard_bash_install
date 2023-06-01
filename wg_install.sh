#!/bin/bash

# Install WireGuard
apt update
apt install -y wireguard

# Generate server keys
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo $SERVER_PRIVATE_KEY | wg pubkey)

# Create WireGuard configuration file
cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $SERVER_PRIVATE_KEY
Address = 10.0.0.1/24
ListenPort = 51820

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
AllowedIPs = 10.0.0.0/24
EOF

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Start WireGuard
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# Output server keys
echo "Server private key: $SERVER_PRIVATE_KEY"
echo "Server public key: $SERVER_PUBLIC_KEY"

#sudo iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o ens3 -j MASQUERADE

