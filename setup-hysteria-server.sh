#!/bin/bash


echo "=== Created by M.Reza Hoseiny Nasab ==="
echo "=== Hysteria Server Setup ==="

read -p "🔒 Enter port to listen on: " PORT
read -p "🛡️ Enter strong password for auth(Could be whatever,just provide it to the clients): " AUTH_PASSWORD
read -p "🧅 Enter obfuscation password(Could be whatever,just provide it to the clients): " OBFS_PASSWORD

echo "📥 Downloading Hysteria..."
wget https://raw.githubusercontent.com/mrhn3242/WgOverHysteria/main/hysteria-linux-amd64 -O /usr/local/bin/hysteria
chmod +x /usr/local/bin/hysteria

echo "📁 Creating certs..."
mkdir -p /etc/hysteria
openssl ecparam -genkey -name prime256v1 -out /etc/hysteria/private.key
openssl req -new -x509 -days 3650 -key /etc/hysteria/private.key -out /etc/hysteria/cert.pem -subj "/CN=hysteria"

echo "📝 Writing config file..."
cat > /etc/hysteria/config.yaml <<EOF
listen: :$PORT

tls:
  cert: /etc/hysteria/cert.pem
  key: /etc/hysteria/private.key

auth:
  type: password
  password: $AUTH_PASSWORD

quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 8388608
  initConnReceiveWindow: 20971520
  maxConnReceiveWindow: 20971520
  maxIdleTimeout: 30s
  maxIncomingStreams: 1024
  disablePathMTUDiscovery: false

obfs:
  type: salamander
  salamander:
    password: $OBFS_PASSWORD

protocol: faketcp

udp:
  idle_timeout: 30s
EOF

echo "Running hysteria server..."

nohup hysteria server -c /etc/hysteria/config.yaml > /var/log/hysteria.log 2>&1 &

echo "✅ Server setup complete."
