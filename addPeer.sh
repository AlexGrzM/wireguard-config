#!/bin/bash

# Usage:
# ./wg-client.sh <server_public_ip> <client_name> <client_ip/cidr> [Destination IPs of packets sent to the remote wireguard server]
#
# Example:
# ./wg-client.sh 203.0.113.10 laptop 10.0.0.2/32 0.0.0.0/0

set -e

WG_IF="wg0"
WG_CONF="/etc/wireguard/${WG_IF}.conf"
WG_DIR="/etc/wireguard"

SERVER_IP="$1"
CLIENT_NAME="$2"
CLIENT_IP="$3"
ALLOWED_IPS="${4:-0.0.0.0/0}"

if [[ -z "$SERVER_IP" || -z "$CLIENT_NAME" || -z "$CLIENT_IP" ]]; then
    echo "Usage: $0 <server_public_ip> <config_name> <client_ip/cidr> [allowed_ips]"
    exit 1
fi

# Read server settings
SERVER_PUBKEY=$(cat "${WG_DIR}/public.key")
SERVER_PORT=$(grep -i '^ListenPort' "$WG_CONF" | awk '{print $3}')

if [[ -z "$SERVER_PORT" ]]; then
    echo "Could not determine ListenPort from $WG_CONF"
    exit 1
fi

# Generate client keys
CLIENT_PRIVKEY=$(wg genkey)
CLIENT_PUBKEY=$(echo "$CLIENT_PRIVKEY" | wg pubkey)

# Append peer to server config
cat >> "$WG_CONF" <<EOF

[Peer]
# $CLIENT_NAME
PublicKey = $CLIENT_PUBKEY
AllowedIPs = $CLIENT_IP
EOF

# Apply peer live (no restart required)
wg set "$WG_IF" peer "$CLIENT_PUBKEY" allowed-ips "$CLIENT_IP"

# Create client config
CLIENT_CONF="${CLIENT_NAME}.conf"

cat > "$CLIENT_CONF" <<EOF
[Interface]
PrivateKey = $CLIENT_PRIVKEY
Address = $CLIENT_IP

[Peer]
PublicKey = $SERVER_PUBKEY
Endpoint = $SERVER_IP:$SERVER_PORT
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25
EOF

chmod 600 "$CLIENT_CONF"

echo "======"
echo "Client created: $CLIENT_NAME"
echo "Client IP: $CLIENT_IP"
echo "Server endpoint: $SERVER_IP:$SERVER_PORT"
echo "Client config: $CLIENT_CONF"
echo "======"