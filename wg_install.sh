#!/bin/bash

# Define log file
LOGFILE="/var/log/wg_install.log"

# Function to write to log file
write_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOGFILE"
}

# Ensure script is running as root
if [ "$(id -u)" -ne 0 ]; then
    write_log "This script must be run as root."
    exit 1
fi

# Install WireGuard
write_log "Starting WireGuard installation..."
# Remove any existing wg0 interface
if ip link show wg0 > /dev/null 2>&1; then
    write_log "Removing existing wg0 interface..."
    wg-quick down wg0 >> "$LOGFILE" 2>&1 || write_log "ERROR: Failed to bring down wg0 interface."
    ip link del dev wg0 >> "$LOGFILE" 2>&1 || write_log "ERROR: Failed to delete wg0 interface."
fi

apt-get update -y >> "$LOGFILE" 2>&1 || write_log "ERROR: Failed to update package list."
apt-get install -y wireguard >> "$LOGFILE" 2>&1 || write_log "ERROR: WireGuard installation failed."

# Generate server keys
write_log "Generating server keys..."
SERVER_PRIVATE_KEY=$(wg genkey) || write_log "ERROR: Failed to generate server private key."
SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey) || write_log "ERROR: Failed to generate server public key."

# Create WireGuard configuration file
write_log "Creating WireGuard configuration..."
cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $SERVER_PRIVATE_KEY
Address = 10.0.0.1/24
ListenPort = 51820
EOF

# Enable IP forwarding
write_log "Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf && sysctl -p >> "$LOGFILE" 2>&1 || write_log "ERROR: Failed to set up IP forwarding."

# Start WireGuard
write_log "Starting WireGuard..."
systemctl enable wg-quick@wg0 >> "$LOGFILE" 2>&1 || write_log "ERROR: Failed to enable WireGuard."
systemctl start wg-quick@wg0 >> "$LOGFILE" 2>&1 || write_log "ERROR: Failed to start WireGuard."

# Output server keys
write_log "Server private key: $SERVER_PRIVATE_KEY"
write_log "Server public key: $SERVER_PUBLIC_KEY"

# Uncomment and adjust this line according to your network interface
#iptables command should be modified according to your network interface
#sudo iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o ens3 -j MASQUERADE

write_log "WireGuard installation complete."


#sudo iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o ens3 -j MASQUERADE

