#!/bin/bash
echo "=== Created by M.Reza Hoseiny Nasab ==="
echo "=== Hysteria Client Setup ==="

read -p "🌐 Enter server IP and port (e.g. 1.2.3.4:443): " SERVER
read -p "🔐 Enter auth password(Must be the same as server): " AUTH_PASSWORD
read -p "🧅 Enter obfuscation password(Must be the same as server): " OBFS_PASSWORD
read -p "🚪 Enter Wiregurad port: " WIREGUARD_PORT

echo "📥 Downloading Hysteria..."
wget https://raw.githubusercontent.com/mrhn3242/WgOverHysteria/main/hysteria-linux-amd64 -O /usr/local/bin/hysteria
chmod +x /usr/local/bin/hysteria

echo "📦 Installing WireGuard..."
apt update -y && apt install -y wireguard

echo "📝 Writing Hysteria config..."
mkdir -p /etc/hysteria
cat > /etc/hysteria/config.yaml <<EOF
server: $SERVER
auth: $AUTH_PASSWORD

tls:
  insecure: true

protocol: faketcp

obfs:
  type: salamander
  salamander:
    password: $OBFS_PASSWORD

quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 8388608
  initConnReceiveWindow: 20971520
  maxConnReceiveWindow: 20971520
  maxIdleTimeout: 30s
  maxIncomingStreams: 1024
  disablePathMTUDiscovery: false

mode: tun

tun:
  name: "hystun0"
  mtu: 1300
  timeout: 5m
EOF

echo "✅ Client setup complete"
echo "Now configuring the wireguard service..."


echo "📝 Writing WireGuard config..."
mkdir -p /etc/wireguard
cat > /etc/wireguard/wg1.conf <<EOF
[Interface]
Address = 190.22.0.1/24
PrivateKey = sJfhQdbPUld9G7vRau3Cd7swekU54Vfur9/ErZIuTVw=
ListenPort = $WIREGUARD_PORT
Table = 124
MTU = 1300

PreUp = sysctl -w net.ipv4.ip_forward=1
PreUp = bash -c 'hysteria client -c /etc/hysteria/config.yaml > /var/log/hysteria.log 2>&1 & sleep 2'

PostUp = ip route flush table 123 || true
PostUp = ip route add default via 100.100.100.102 dev hystun0 table 123 || true
PostUp = ip route add 190.22.0.0/24 dev wg1 table 123 || true
PostUp = ip rule add fwmark 123 table 123 || true
PostUp = iptables -t mangle -A PREROUTING -i hystun0 -j MARK --set-mark 123
PostUp = iptables -t nat -A POSTROUTING -o hystun0 -j MASQUERADE
PostUp = iptables -A FORWARD -i wg1 -o hystun0 -j ACCEPT
PostUp = iptables -A FORWARD -i hystun0 -o wg1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
PostUp = ip route add default via 100.100.100.102 dev hystun0 table 124 || true
PostUp = ip rule add from 190.22.0.0/24 lookup 124 || true

PostDown = ip route flush table 123 || true
PostDown = ip rule del fwmark 123 || true
PostDown = iptables -t mangle -D PREROUTING -i hystun0 -j MARK --set-mark 123
PostDown = iptables -t nat -D POSTROUTING -o hystun0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg1 -o hystun0 -j ACCEPT
PostDown = iptables -D FORWARD -i hystun0 -o wg1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
PostDown = ip route del default via 100.100.100.102 dev hystun0 table 124 || true
PostDown = ip rule del from 190.22.0.0/24 lookup 124 || true
PostDown = killall hysteria || true
EOF

echo "✅ Wireguard setup completed. reboot your server"
echo "After reboot run sudo wg-quick up wg1"
