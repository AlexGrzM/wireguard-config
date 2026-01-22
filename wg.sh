#!/bin/bash

# wg.sh <interface_ip/cidr> <listen_port> <Enable_Peer_to_Peer>

IFACE_IP="$1"
PORT="$2"
FORWARD="$3"

set -e

# Install WireGuard
apt update
apt install -y wireguard

# Generate keys
wg genkey | tee /etc/wireguard/private.key
chmod 600 /etc/wireguard/private.key

wg pubkey < /etc/wireguard/private.key | tee /etc/wireguard/public.key

PRIVATE_KEY=$(cat /etc/wireguard/private.key)

# Create WireGuard config
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = $PRIVATE_KEY
Address = $IFACE_IP
ListenPort = $PORT
EOF

# Enable IP forwarding if requested
if [[ "$FORWARD" == "1" ]]; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p
fi

# Allow WireGuard port
ufw allow ${PORT}/udp

# Enable and start WireGuard
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

echo
echo "======"
echo "Setup complete."
echo "Interface IP: $IFACE_IP"
echo "Port: $PORT"
echo "Server public key:"
cat /etc/wireguard/public.key
